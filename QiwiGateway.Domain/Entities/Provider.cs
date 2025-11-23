namespace QiwiGateway.Domain.Entities;

public class Provider
{
    public int Id { get; set; } // 👈 Это будет PK
    public string Name { get; set; } = default!;
    public string Code { get; set; } = default!;
}