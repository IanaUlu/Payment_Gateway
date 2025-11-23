using QiwiGateway.Application.Protocols.Common;
namespace QiwiGateway.Application.Protocols.Test;

public class TestErrorCodeMapper : IErrorCodeMapper
{
    private static readonly Dictionary<int, int> CodeMap = new()
    {
        [2] = 0,     // OK
        [3] = 1,     // Timeout (for retry testing)
        [1] = 300,   // Another timeout code
        [99] = 79    // Account not found
    };

    public int Map(int providerCode) => CodeMap.TryGetValue(providerCode, out var mapped) ? mapped : 13; // default: format error
}