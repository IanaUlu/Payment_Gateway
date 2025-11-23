namespace QiwiGateway.Application.Protocols.Common;

public interface IErrorCodeMapper
{
    int Map(int providerCode);
}
