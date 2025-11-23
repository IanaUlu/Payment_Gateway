using QiwiGateway.Application.Protocols.Common;
using QiwiGateway.Application.Logging;
using QiwiGateway.Domain.Protocols;
using System.Reflection.Metadata;


namespace QiwiGateway.Application.Protocols.Test;

public class TestProtocol : IProviderProtocol
{
    private readonly TestErrorCodeMapper _mapper;
    private readonly ILogWriter _logWriter;
    private static int _timeoutCallCount = 0; // Call counter for TIMEOUT account

    public TestProtocol(TestErrorCodeMapper mapper, ILogWriter logWriter)
    {
        _mapper = mapper;
        _logWriter = logWriter;
    }

    public async Task<ProviderResponse> ProcessAsync(PaymentRequest request)
    {
        int rawCode;
        string comment;

        switch (request.Command?.ToLowerInvariant())
        {
            case "check":
                rawCode = SimulateCheck(request);
                comment = $"TestProtocol: check for account {request.Account}";
                break;

            case "pay":
                rawCode = SimulatePay(request);
                comment = $"TestProtocol: pay for account {request.Account}, amount {request.Sum}";
                break;

            default:
                rawCode = 13;
                comment = $"TestProtocol: Unknown command {request.Command}";
                break;
        }

        var mappedCode = _mapper.Map(rawCode);

        var response = new ProviderResponse
        {
            ResultCode = mappedCode,
            Comment = comment
        };

        await _logWriter.LogInfoAsync("TestProtocol response", new Dictionary<string, string>
        {
            { "PrvId", request.PrvId.ToString() },
            { "Command", request.Command ?? "" },
            { "Account", request.Account },
            { "TxnId", request.TxnId },
            { "ResultCode", response.ResultCode.ToString() },
            { "Comment", response.Comment ?? "" }
        });

        return response;
    }

    private int SimulateCheck(PaymentRequest request)
    {
        var account = request.Account?.Trim();
        return account == "123456" ? 2 : 99;
    }

    private int SimulatePay(PaymentRequest request)
    {
        var account = request.Account?.Trim();

        // Special account for timeout simulation
        if (account == "TIMEOUT")
        {
            _timeoutCallCount++;
            // First call - timeout, second - success
            return _timeoutCallCount == 1 ? 3 : 2;
        }

        if (account != "123456")
            return 99;

        if (request.Sum <= 0)
            return 1;

        return 2; // Success
    }
}