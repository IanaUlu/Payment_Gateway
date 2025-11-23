using FluentAssertions;
using QiwiGateway.Application.Logging;
using QiwiGateway.Application.Protocols.Test;
using QiwiGateway.Domain.Protocols;
using Xunit;

namespace QiwiGateway.Tests.UnitTests;

public class TestProtocolTests
{
    private readonly TestProtocol _protocol;
    private readonly FakeLogWriter _logWriter;

    public TestProtocolTests()
    {
        _logWriter = new FakeLogWriter();
        var mapper = new TestErrorCodeMapper();
        _protocol = new TestProtocol(mapper, _logWriter);
    }

    [Fact]
    public async Task ProcessAsync_CheckCommand_ValidAccount_ReturnsSuccess()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "check",
            Account = "123456",
            Sum = 100,
            TxnId = "TEST001",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(0);
        response.Comment.Should().Contain("check for account 123456");
    }

    [Fact]
    public async Task ProcessAsync_CheckCommand_InvalidAccount_ReturnsAccountNotFound()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "check",
            Account = "999999",
            Sum = 100,
            TxnId = "TEST002",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(79, "invalid account should return code 79");
        response.Comment.Should().Contain("check for account 999999");
    }

    [Fact]
    public async Task ProcessAsync_PayCommand_ValidAccount_ReturnsSuccess()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "pay",
            Account = "123456",
            Sum = 500,
            TxnId = "PAY001",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(0);
        response.Comment.Should().Contain("pay for account 123456");
        response.Comment.Should().Contain("amount 500");
    }

    [Fact]
    public async Task ProcessAsync_PayCommand_InvalidAccount_ReturnsAccountNotFound()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "pay",
            Account = "000000",
            Sum = 100,
            TxnId = "PAY002",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(79);
    }

    [Fact]
    public async Task ProcessAsync_PayCommand_ZeroSum_ReturnsError()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "pay",
            Account = "123456",
            Sum = 0,
            TxnId = "PAY003",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(300, "zero sum should return error code 300");
    }

    [Fact]
    public async Task ProcessAsync_PayCommand_NegativeSum_ReturnsError()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "pay",
            Account = "123456",
            Sum = -50,
            TxnId = "PAY004",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(300);
    }

    [Fact]
    public async Task ProcessAsync_UnknownCommand_ReturnsFormatError()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "unknown",
            Account = "123456",
            Sum = 100,
            TxnId = "TEST005",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(13, "unknown commands return format error");
        response.Comment.Should().Contain("Unknown command");
    }

    [Fact]
    public async Task ProcessAsync_TimeoutAccount_FirstCall_ReturnsTimeout()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "pay",
            Account = "TIMEOUT",
            Sum = 100,
            TxnId = "TIMEOUT001",
            PrvId = 100001
        };

        // Act
        var response = await _protocol.ProcessAsync(request);

        // Assert
        response.ResultCode.Should().Be(1, "first call to TIMEOUT account returns timeout");
    }

    [Fact]
    public async Task ProcessAsync_ShouldLogResponse()
    {
        // Arrange
        var request = new PaymentRequest
        {
            Command = "check",
            Account = "123456",
            Sum = 100,
            TxnId = "LOG_TEST",
            PrvId = 100001
        };

        // Act
        await _protocol.ProcessAsync(request);

        // Assert
        _logWriter.InfoLogs.Should().ContainSingle();
        _logWriter.InfoLogs[0].Message.Should().Be("TestProtocol response");
    }
}

// Fake logger for testing
public class FakeLogWriter : ILogWriter
{
    public List<(string Message, Dictionary<string, string> Data)> InfoLogs { get; } = new();
    public List<(string Message, Exception Ex)> ErrorLogs { get; } = new();

    public Task LogInfoAsync(string message, Dictionary<string, string> data)
    {
        InfoLogs.Add((message, data));
        return Task.CompletedTask;
    }

    public Task LogErrorAsync(string message, Exception ex)
    {
        ErrorLogs.Add((message, ex));
        return Task.CompletedTask;
    }
}
