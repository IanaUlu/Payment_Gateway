namespace QiwiGateway.Domain.Entities;

public class Account
{
    public int Id { get; set; }
    public string AccountNumber { get; set; } = "";
    public bool IsActive { get; set; } = true;
}