using MediatR;
using QiwiGateway.Infrastructure.Data;
using QiwiGateway.Domain.Entities;

namespace QiwiGateway.Application.Transactions.Commands.CreateTransaction;

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
            PrvId = request.PrvId,
            TxnId = request.TxnId,
            AccountNumber = request.AccountNumber,
            Amount = request.Amount,
            Status = request.OsmpCode == "0" ? "success" : (request.OsmpCode == "1" ? "timeout" : "failed"),
            OsmpCode = request.OsmpCode,
            PayType = request.PayType,
            ExtraData = request.ExtraData != null && request.ExtraData.Count > 0 
                ? System.Text.Json.JsonSerializer.Serialize(request.ExtraData) 
                : null,
            CreatedAt = DateTime.UtcNow
        };

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