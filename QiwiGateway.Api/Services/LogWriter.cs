using QiwiGateway.Api.Helpers;
using QiwiGateway.Api.Interfaces;
using QiwiGateway.Application.Logging;

namespace QiwiGateway.Api.Services;

public class LogWriter : IApiLogWriter, ILogWriter
{
    private readonly string _logDir;

    public LogWriter()
    {
        _logDir = Path.Combine(AppContext.BaseDirectory, "Logs");
        Directory.CreateDirectory(_logDir);
    }

    private string GetLogFilePath() =>
        Path.Combine(_logDir, $"log_{DateTime.UtcNow:yyyy-MM-dd}.txt");

    private string Timestamp =>
        TimeHelper.FormatForLog();

    // IApiLogWriter

    public async Task LogRawQueryAsync(string ipAddress, string query)
    {
        var line = $"{Timestamp} | IP={ipAddress} | RAW_QUERY | {query}";
        await File.AppendAllTextAsync(GetLogFilePath(), line + Environment.NewLine);
    }

    public async Task LogRequestAsync(string ipAddress, string command, Dictionary<string, string> parameters)
    {
        var paramString = string.Join(" | ", parameters.Select(kv => $"{kv.Key}={kv.Value}"));
        var line = $"{Timestamp} | IP={ipAddress} | REQUEST | command={command} | {paramString}";
        await File.AppendAllTextAsync(GetLogFilePath(), line + Environment.NewLine);
    }

    public async Task LogResponseAsync(string ipAddress, string txnId, int resultCode, string comment)
    {
        var line = $"{Timestamp} | IP={ipAddress} | RESPONSE | txn_id={txnId} | result={resultCode} | {comment}";
        await File.AppendAllTextAsync(GetLogFilePath(), line + Environment.NewLine);
    }

    // ILogWriter

    public async Task LogInfoAsync(string message, Dictionary<string, string> data)
    {
        var formatted = string.Join(" | ", data.Select(kv => $"{kv.Key}={kv.Value}"));
        var line = $"{Timestamp} | INFO | {message} | {formatted}";
        await File.AppendAllTextAsync(GetLogFilePath(), line + Environment.NewLine);
    }

    public async Task LogErrorAsync(string message, Exception ex)
    {
        var line = $"{Timestamp} | ERROR | {message} | {ex.Message}";
        await File.AppendAllTextAsync(GetLogFilePath(), line + Environment.NewLine);
    }
}