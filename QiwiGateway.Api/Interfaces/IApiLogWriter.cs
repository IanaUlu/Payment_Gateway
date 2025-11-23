namespace QiwiGateway.Api.Interfaces;

public interface IApiLogWriter
{
    Task LogRawQueryAsync(string ipAddress, string query);
    Task LogRequestAsync(string ipAddress, string command, Dictionary<string, string> parameters);
    Task LogResponseAsync(string ipAddress, string txnId, int resultCode, string comment);
}