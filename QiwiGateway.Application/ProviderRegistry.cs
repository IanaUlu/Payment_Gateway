using QiwiGateway.Application.Protocols.Test;
// using QiwiGateway.Application.Protocols.Mobile;
// using QiwiGateway.Application.Protocols.Aggregators;

namespace QiwiGateway.Application.Protocols;

public static class ProviderRegistry
{
    public static readonly Dictionary<string, Type> Map = new()
    {
        ["100001"] = typeof(TestProtocol)
        // ["123"] = typeof(MobileProtocol)
        // ["456"] = typeof(AggregatorProtocol)
    };
}