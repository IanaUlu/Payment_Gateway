using MediatR;
using QiwiGateway.Domain.Entities;
using QiwiGateway.Infrastructure.Data;

namespace QiwiGateway.Application.Transactions.Commands;

public class CreateTransactionHandler : IRequestHandler<CreateTransactionCommand, string>
{
    private readonly QiwiDbContext _context;

    public CreateTransactionHandler(QiwiDbContext context)
    {
        _context = context;
    }

    public async Task<string> Handle(CreateTransactionCommand request, CancellationToken cancellationToken)
    {
        var transaction = new Transaction
        {
            BePayTxnId = GenerateTransactionId(),
            TxnId = request.TxnId,
            PrvId = request.PrvId,
            AccountNumber = request.AccountNumber,
            Amount = request.Amount,
            PayType = request.PayType,
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };

        if (request.ExtraData != null && request.ExtraData.Any())
        {
            transaction.ExtraData = string.Join(";", request.ExtraData.Select(kv => $"{kv.Key}={kv.Value}"));
        }

        _context.Transactions.Add(transaction);
        await _context.SaveChangesAsync(cancellationToken);

        return transaction.BePayTxnId;
    }

    private string GenerateTransactionId()
    {
        var timestamp = DateTime.UtcNow.ToString("yyMMddHHmmss"); 
        var random = Random.Shared.Next(100, 999);                
        return $"{timestamp}{random}";                            
    }
}