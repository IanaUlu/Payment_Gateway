using QiwiGateway.Domain.Protocols;

namespace QiwiGateway.Application.Protocols;

public class ProviderResolver
{
    private readonly IServiceProvider _provider;

    public ProviderResolver(IServiceProvider provider)
    {
        _provider = provider;
    }

    public IProviderProtocol? Resolve(string prvId)
    {
        if (ProviderRegistry.Map.TryGetValue(prvId, out var type))
        {
            return _provider.GetService(type) as IProviderProtocol;
        }

        return null;
    }
}