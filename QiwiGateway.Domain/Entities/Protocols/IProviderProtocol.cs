namespace QiwiGateway.Domain.Protocols;

public interface IProviderProtocol
{
    Task<ProviderResponse> ProcessAsync(PaymentRequest request);
}