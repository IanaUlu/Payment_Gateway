namespace QiwiGateway.Domain.Protocols;

public class PaymentRequest
{
    public string Account { get; set; }
    public string TxnId { get; set; }
    public decimal Sum { get; set; }
    public int PrvId { get; set; }
    public string Command { get; set; }
    public Dictionary<string, string> Data { get; set; }
    public string ServiceCode { get; set; } // для агрегаторов
}