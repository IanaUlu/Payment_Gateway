using System.Net;
using System.Xml.Linq;
using FluentAssertions;
using Xunit;

namespace QiwiGateway.Tests.IntegrationTests;

public class CheckCommandIntegrationTests : IClassFixture<QiwiGatewayWebApplicationFactory>
{
    private readonly HttpClient _client;

    public CheckCommandIntegrationTests(QiwiGatewayWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Check_ValidAccount_ReturnsSuccess()
    {
        // Arrange
        var url = "/payment_app.cgi?command=check&txn_id=CHECK_001&account=123456&sum=100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var osmpTxnId = xml.Root.Element("osmp_txn_id")!.Value;
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(0, "valid account should return success");
        osmpTxnId.Should().Be("CHECK_001");
        comment.Should().Contain("123456");
    }

    [Fact]
    public async Task Check_InvalidAccount_ReturnsAccountNotFound()
    {
        // Arrange
        var url = "/payment_app.cgi?command=check&txn_id=CHECK_002&account=999999&sum=100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);

        result.Should().Be(79, "invalid account should return account not found");
    }

    [Fact]
    public async Task Check_WithoutTxnId_ReturnsSuccess()
    {
        // Arrange
        var url = "/payment_app.cgi?command=check&account=123456&sum=100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);

        result.Should().Be(0, "CHECK command does not require txn_id");
    }

    [Fact]
    public async Task Check_WithZeroSum_ReturnsSuccess()
    {
        // Arrange
        var url = "/payment_app.cgi?command=check&txn_id=CHECK_003&account=123456&sum=0&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);

        result.Should().Be(0, "CHECK command allows zero sum");
    }

    [Fact]
    public async Task Check_WithoutAccount_ReturnsMissingAccount()
    {
        // Arrange
        var url = "/payment_app.cgi?command=check&txn_id=CHECK_004&sum=100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(302);
        comment.Should().Contain("Missing account");
    }

    [Fact]
    public async Task Check_InvalidProvider_ReturnsProviderNotFound()
    {
        // Arrange
        var url = "/payment_app.cgi?command=check&txn_id=CHECK_005&account=123456&sum=100&prv_id=999";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(5);
        comment.Should().Contain("Provider");
        comment.Should().Contain("999");
    }
}
