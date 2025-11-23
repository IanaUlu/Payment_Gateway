using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QiwiGateway.Api.Interfaces;
using QiwiGateway.Application.Protocols;
using QiwiGateway.Application.Transactions.Commands.CreateTransaction;
using QiwiGateway.Domain.Protocols;
using QiwiGateway.Infrastructure.Data;
using System.Globalization;
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

        // Filter data, excluding standard QIWI API parameters
        var standardParams = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "command", "txn_id", "account", "sum", "prv_id", "txn_date", "pay_type"
        };
        
        var extraData = data?
            .Where(kv => !standardParams.Contains(kv.Key))
            .ToDictionary(kv => kv.Key, kv => kv.Value);

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
        { "data", extraData != null && extraData.Count > 0 ? string.Join(", ", extraData.Select(kv => $"{kv.Key}={kv.Value}")) : "none" }
    };

        await _logWriter.LogRequestAsync(ipAddress, command, parameters);

        if (!decimal.TryParse(sum, NumberStyles.Number, CultureInfo.InvariantCulture, out var parsedSum))
        {
            parsedSum = 0;
        }

        int resultCode;
        string comment;

        var protocol = _providerResolver.Resolve(prvId.ToString());
        if (protocol == null)
        {
            resultCode = 5;
            comment = $"Provider with prv_id={prvId} not found";
        }
        else if (string.IsNullOrWhiteSpace(account))
        {
            resultCode = 302;
            comment = "Missing account";
        }
        else if (command?.ToLower() != "check" && string.IsNullOrWhiteSpace(txnId))
        {
            // For all commands except CHECK, txn_id is required
            resultCode = 300;
            comment = "Missing txn_id";
        }
        else if (command?.ToLower() != "check" && parsedSum <= 0)
        {
            // For all commands except CHECK, sum must be > 0
            resultCode = 301;
            comment = "Invalid sum";
        }
        else if (command?.ToLower() == "pay")
        {
            // Look for existing transaction with this TxnId
            var existingTransaction = await _context.Transactions
                .FirstOrDefaultAsync(t => t.TxnId == txnId && t.PrvId == prvId, HttpContext.RequestAborted);

            if (existingTransaction != null)
            {
                // Check previous processing code
                if (existingTransaction.OsmpCode == "1")
                {
                    // Code 1 = timeout, allow retry to provider
                    var request = new PaymentRequest
                    {
                        Account = account?.Trim() ?? "",
                        Sum = parsedSum,
                        TxnId = txnId,
                        PrvId = prvId,
                        Command = command?.Trim(),
                        Data = extraData ?? new Dictionary<string, string>(),
                        ServiceCode = ""
                    };

                    var providerResponse = await protocol.ProcessAsync(request);
                    resultCode = providerResponse.ResultCode;
                    comment = providerResponse.Comment ?? "";

                    // Update transaction with new code
                    existingTransaction.OsmpCode = resultCode.ToString();
                    existingTransaction.Status = resultCode == 0 ? "success" : (resultCode == 1 ? "timeout" : "failed");
                    existingTransaction.CreatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync(HttpContext.RequestAborted);

                    comment = $"Timeout retry. BePayTxnId={existingTransaction.BePayTxnId}. {comment}";
                }
                else
                {
                    // For all other codes (0, 2, 5, 99, etc.) - return existing code
                    resultCode = int.Parse(existingTransaction.OsmpCode);
                    comment = $"Duplicate txn_id={txnId}. Previous result={resultCode}. BePayTxnId={existingTransaction.BePayTxnId}";
                }
            }
            else
            {
                // First request with this TxnId - create new transaction
                var request = new PaymentRequest
                {
                    Account = account?.Trim() ?? "",
                    Sum = parsedSum,
                    TxnId = txnId,
                    PrvId = prvId,
                    Command = command?.Trim(),
                    Data = extraData ?? new Dictionary<string, string>(),
                    ServiceCode = ""
                };

                var providerResponse = await protocol.ProcessAsync(request);
                resultCode = providerResponse.ResultCode;
                comment = providerResponse.Comment ?? "";

                var commandObj = new CreateTransactionCommand
                {
                    TxnId = txnId,
                    PrvId = prvId,
                    AccountNumber = account,
                    Amount = parsedSum,
                    PayType = payType,
                    ExtraData = extraData,
                    OsmpCode = resultCode.ToString(),
                };

                var bepayTxnId = await _mediator.Send(commandObj);
                comment = $"Payment processed. BePayTxnId={bepayTxnId}. {comment}";
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
                Data = extraData ?? new Dictionary<string, string>(),
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
            return Content("Log file not found", "text/plain", Encoding.UTF8);

        var logContent = System.IO.File.ReadAllText(logFile);
        return Content(logContent, "text/plain", Encoding.UTF8);
    }

    [HttpGet("view-log-by-date")]
    public IActionResult ViewLogByDate([FromQuery] DateTime date)
    {
        var logDir = Path.Combine(AppContext.BaseDirectory, "Logs");
        var logFile = Path.Combine(logDir, $"log_{date:yyyy-MM-dd}.txt");

        if (!System.IO.File.Exists(logFile))
            return Content($"Log file for {date:yyyy-MM-dd} not found", "text/plain", Encoding.UTF8);

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
