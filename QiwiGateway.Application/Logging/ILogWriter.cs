namespace QiwiGateway.Application.Logging;
public interface ILogWriter
{
    Task LogInfoAsync(string message, Dictionary<string, string> data);
    Task LogErrorAsync(string message, Exception ex);
}