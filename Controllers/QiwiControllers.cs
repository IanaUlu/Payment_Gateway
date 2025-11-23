using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QiwiGateway.Api.Interfaces;
using QiwiGateway.Application.Protocols;
using QiwiGateway.Application.Transactions.Commands.CreateTransaction;
using QiwiGateway.Domain.Protocols;
using QiwiGateway.Infrastructure.Data;
using System.Text;
using System.Xml.Serialization;

[ApiController]
[Route("payment_app.cgi")]
[Produces("application/xml")]
public class QiwiController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly QiwiDbContext _context;
    private readonly IApiLogWriter _logWriter;
    private readonly ProviderResolver _providerResolver;

    public QiwiController(IMediator mediator, QiwiDbContext context, IApiLogWriter logWriter, ProviderResolver providerResolver)
    {
        _mediator = mediator;
        _context = context;
        _logWriter = logWriter;
        _providerResolver = providerResolver;
    }

    [HttpGet]
    [HttpPost]
    public async Task<IActionResult> Handle(
      [FromQuery(Name = "command")] string command,
      [FromQuery(Name = "txn_id")] string txnId,
      [FromQuery(Name = "account")] string? account,
      [FromQuery(Name = "sum")] string sum,
      [FromQuery(Name = "prv_id")] int prvId,
      [FromQuery(Name = "txn_date")] string? txnDate = null,
      [FromQuery(Name = "pay_type")] string? payType = null,
      [FromQuery] Dictionary<string, string>? data = null
  )
    {
        ModelState.Clear();

        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        await _logWriter.LogRawQueryAsync(ipAddress, HttpContext.Request.QueryString.Value ?? "");

        var parameters = new Dictionary<string, string>
    {
        { "txn_id", txnId },
        { "account", account },
        { "sum", sum },
        { "prv_id", prvId.ToString() },
        { "pay_type", payType ?? "" },
        { "txn_date", txnDate ?? "" },
        { "data", data != null ? string.Join(", ", data.Select(kv => $"{kv.Key}={kv.Value}")) : "none" }
    };

        await _logWriter.LogRequestAsync(ipAddress, command, parameters);

        decimal.TryParse(sum, out var parsedSum);

        int resultCode;
        string comment;

        var protocol = _providerResolver.Resolve(prvId.ToString());
        if (protocol == null)
        {
            resultCode = 5;
            comment = $"Provider with prv_id={prvId} not found";
        }
        else if (string.IsNullOrWhiteSpace(txnId))
        {
            resultCode = 300;
            comment = "Missing txn_id";
        }
        else if (string.IsNullOrWhiteSpace(account))
        {
            resultCode = 302;
            comment = "Missing account";
        }
        else if (parsedSum <= 0)
        {
            resultCode = 301;
            comment = "Invalid sum";
        }
        else if (command?.ToLower() == "pay")
        {
            var duplicate = await _context.Transactions
                .AnyAsync(t => t.TxnId == txnId, HttpContext.RequestAborted);

            if (duplicate)
            {
                resultCode = 10;
                comment = $"Duplicate txn_id={txnId}";
            }
            else
            {
                var request = new PaymentRequest
                {
                    Account = account?.Trim() ?? "",
                    Sum = parsedSum,
                    TxnId = txnId,
                    PrvId = prvId,
                    Command = command?.Trim(),
                    Data = data ?? new Dictionary<string, string>(),
                    ServiceCode = ""
                };

                var providerResponse = await protocol.ProcessAsync(request);
                resultCode = providerResponse.ResultCode;
                comment = providerResponse.Comment ?? "";

               // if (resultCode == 0)
               // {
                    var commandObj = new CreateTransactionCommand
                    {
                        TxnId = txnId,
                        PrvId = prvId,
                        AccountNumber = account,
                        Amount = parsedSum,
                        PayType = payType,
                        ExtraData = data,
                        OsmpCode = resultCode.ToString(),
                    };

                    var bepayTxnId = await _mediator.Send(commandObj);
                    comment = $"Payment accepted. BePayTxnId={bepayTxnId}";
               // }
            }
        }
        else
        {
            var request = new PaymentRequest
            {
                Account = account?.Trim() ?? "",
                Sum = parsedSum,
                TxnId = txnId,
                PrvId = prvId,
                Command = command?.Trim(),
                Data = data ?? new Dictionary<string, string>(),
                ServiceCode = ""
            };

            var providerResponse = await protocol.ProcessAsync(request);
            resultCode = providerResponse.ResultCode;
            comment = providerResponse.Comment ?? "";
        }

        await _logWriter.LogResponseAsync(ipAddress, txnId, resultCode, comment);

        var response = new QiwiResponse
        {
            OsmpTxnId = txnId ?? "",
            Result = resultCode,
            Comment = comment
        };

        var serializer = new XmlSerializer(typeof(QiwiResponse));
        var ns = new XmlSerializerNamespaces();
        ns.Add("", "");

        using var stringWriter = new Utf8StringWriter();
        serializer.Serialize(stringWriter, response, ns);

        return Content(stringWriter.ToString(), "application/xml", Encoding.UTF8);
    }

    [HttpGet("download-log")]
    public IActionResult DownloadLog()
    {
        var logDir = Path.Combine(AppContext.BaseDirectory, "Logs");
        var logFile = Path.Combine(logDir, $"log_{DateTime.UtcNow:yyyy-MM-dd}.txt");

        if (!System.IO.File.Exists(logFile))
            return NotFound("Log file not found");

        var fileBytes = System.IO.File.ReadAllBytes(logFile);
        var fileName = Path.GetFileName(logFile);

        return File(fileBytes, "text/plain", fileName);
    }

    [HttpGet("view-log")]
    public IActionResult ViewLog()
    {
        var logDir = Path.Combine(AppContext.BaseDirectory, "Logs");
        var logFile = Path.Combine(logDir, $"log_{DateTime.UtcNow:yyyy-MM-dd}.txt");

        if (!System.IO.File.Exists(logFile))
            return Content("Лог-файл не найден", "text/plain", Encoding.UTF8);

        var logContent = System.IO.File.ReadAllText(logFile);
        return Content(logContent, "text/plain", Encoding.UTF8);
    }

    [HttpGet("view-log-by-date")]
    public IActionResult ViewLogByDate([FromQuery] DateTime date)
    {
        var logDir = Path.Combine(AppContext.BaseDirectory, "Logs");
        var logFile = Path.Combine(logDir, $"log_{date:yyyy-MM-dd}.txt");

        if (!System.IO.File.Exists(logFile))
            return Content($"Лог-файл за {date:yyyy-MM-dd} не найден", "text/plain", Encoding.UTF8);

        var logContent = System.IO.File.ReadAllText(logFile);
        return Content(logContent, "text/plain", Encoding.UTF8);
    }
}

[XmlRoot("response")]
public class QiwiResponse
{
    [XmlElement("osmp_txn_id")] public string OsmpTxnId { get; set; } = "";
    [XmlElement("result")] public int Result { get; set; }
    [XmlElement("comment")] public string? Comment { get; set; }
}

public class Utf8StringWriter : StringWriter
{
    public override Encoding Encoding => Encoding.UTF8;
}
