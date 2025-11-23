using MediatR;
using Microsoft.EntityFrameworkCore;
using QiwiGateway.Domain.Entities;
using QiwiGateway.Infrastructure.Data;

namespace QiwiGateway.Application.Transactions.Queries;

public class GetTransactionByIdHandler : IRequestHandler<GetTransactionByIdQuery, Transaction?>
{
    private readonly QiwiDbContext _context;

    public GetTransactionByIdHandler(QiwiDbContext context)
    {
        _context = context;
    }

    public async Task<Transaction?> Handle(GetTransactionByIdQuery request, CancellationToken cancellationToken)
    {
        return await _context.Transactions
            .FirstOrDefaultAsync(t => t.BePayTxnId == request.BePayTxnId, cancellationToken);
    }
}