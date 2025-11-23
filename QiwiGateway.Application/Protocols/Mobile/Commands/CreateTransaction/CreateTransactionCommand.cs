using MediatR;

namespace QiwiGateway.Application.Transactions.Commands;

public class CreateTransactionCommand : IRequest<string>
{
    public string TxnId { get; set; } = default;
    public int PrvId { get; set; }
    public string AccountNumber { get; set; } = "";
    public decimal Amount { get; set; }

    public string? PayType { get; set; }
    public Dictionary<string, string>? ExtraData { get; set; }
}