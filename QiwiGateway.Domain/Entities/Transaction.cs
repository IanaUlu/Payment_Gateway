using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;


namespace QiwiGateway.Domain.Entities;

public class Transaction
{
    [Key]
    public string BePayTxnId { get; set; }

    [NotMapped]
    public string BePayTxnIdString => BePayTxnId.ToString();

    public int PrvId { get; set; }
    public string TxnId { get; set; } = "";

    public string OsmpCode {  get; set; }
    public string AccountNumber { get; set; } = "";
    public decimal Amount { get; set; }

    public string? PayType { get; set; } 
    public string? ExtraData { get; set; }

    public string Status { get; set; } = "pending";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}