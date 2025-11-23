namespace QiwiGateway.Api.Models;

public class TransactionDto
{
    public string txn_id { get; set; } = default!;
    public int prv_id { get; set; }
    public string account { get; set; } = default!;
    public decimal sum { get; set; }
    public Dictionary<string, string>? extra_data { get; set; }
}