using MediatR;
using QiwiGateway.Domain.Entities;

namespace QiwiGateway.Application.Transactions.Queries;

public class GetTransactionByIdQuery : IRequest<Transaction?>
{
    public string BePayTxnId { get; }

    public GetTransactionByIdQuery(string bePayTxnId)
    {
        BePayTxnId = bePayTxnId;
    }
}