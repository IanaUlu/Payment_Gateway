using System.Net;
using System.Xml.Linq;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using QiwiGateway.Infrastructure.Data;
using Xunit;

namespace QiwiGateway.Tests.IntegrationTests;

public class PayCommandIntegrationTests : IClassFixture<QiwiGatewayWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly QiwiGatewayWebApplicationFactory _factory;

    public PayCommandIntegrationTests(QiwiGatewayWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    private QiwiDbContext GetDbContext()
    {
        var scope = _factory.Services.CreateScope();
        return scope.ServiceProvider.GetRequiredService<QiwiDbContext>();
    }

    [Fact]
    public async Task Pay_FirstSuccessfulPayment_CreatesTransactionInDatabase()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_INT_001&account=123456&sum=500.50&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(0);
        comment.Should().Contain("Payment processed");
        comment.Should().Contain("BePayTxnId=");

        // Verify database
        using var db = GetDbContext();
        var transaction = db.Transactions.FirstOrDefault(t => t.TxnId == "PAY_INT_001");
        transaction.Should().NotBeNull();
        transaction!.Amount.Should().Be(500.50m);
        transaction.Status.Should().Be("success");
        transaction.OsmpCode.Should().Be("0");
        transaction.PrvId.Should().Be(100001);
    }

    [Fact]
    public async Task Pay_DuplicateSuccessfulPayment_ReturnsDuplicateMessage()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_DUP_001&account=123456&sum=100&prv_id=100001";

        // Act - First request
        await _client.GetAsync(url);
        
        // Act - Second request (duplicate)
        var response2 = await _client.GetAsync(url);

        // Assert
        response2.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response2.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(0);
        comment.Should().Contain("Duplicate");
        comment.Should().Contain("PAY_DUP_001");
        comment.Should().Contain("Previous result=0");
    }

    [Fact]
    public async Task Pay_InvalidAccount_CreatesFailedTransaction()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_ERR_001&account=999999&sum=100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);

        result.Should().Be(79);

        // Verify database
        using var db = GetDbContext();
        var transaction = db.Transactions.FirstOrDefault(t => t.TxnId == "PAY_ERR_001");
        transaction.Should().NotBeNull();
        transaction!.Status.Should().Be("failed");
        transaction.OsmpCode.Should().Be("79");
    }

    [Fact]
    public async Task Pay_DuplicateErrorTransaction_ReturnsPreviousError()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_ERR_DUP_001&account=888888&sum=100&prv_id=100001";

        // Act - First request (error)
        await _client.GetAsync(url);
        
        // Act - Second request (duplicate)
        var response2 = await _client.GetAsync(url);

        // Assert
        response2.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response2.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(79);
        comment.Should().Contain("Duplicate");
        comment.Should().Contain("Previous result=79");
    }

    [Fact]
    public async Task Pay_TimeoutRetry_FirstRequestTimeout_SecondRequestSuccess()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_TIMEOUT_001&account=TIMEOUT&sum=100&prv_id=100001";

        // Act - First request (timeout)
        var response1 = await _client.GetAsync(url);
        var content1 = await response1.Content.ReadAsStringAsync();
        var xml1 = XDocument.Parse(content1);
        var result1 = int.Parse(xml1.Root!.Element("result")!.Value);

        // Assert first request
        result1.Should().Be(1, "first request to TIMEOUT account returns timeout");

        // Verify database after first request
        using (var db = GetDbContext())
        {
            var transaction = db.Transactions.FirstOrDefault(t => t.TxnId == "PAY_TIMEOUT_001");
            transaction.Should().NotBeNull();
            transaction!.OsmpCode.Should().Be("1");
            transaction.Status.Should().Be("timeout", "timeout status should be 'timeout', not 'failed'");
        }

        // Act - Second request (retry after timeout)
        var response2 = await _client.GetAsync(url);
        var content2 = await response2.Content.ReadAsStringAsync();
        var xml2 = XDocument.Parse(content2);
        var result2 = int.Parse(xml2.Root!.Element("result")!.Value);
        var comment2 = xml2.Root.Element("comment")!.Value;

        // Assert second request
        result2.Should().Be(0, "second request to TIMEOUT account succeeds");
        comment2.Should().Contain("Timeout retry");

        // Verify database after second request
        using (var db = GetDbContext())
        {
            var transaction = db.Transactions.FirstOrDefault(t => t.TxnId == "PAY_TIMEOUT_001");
            transaction.Should().NotBeNull();
            transaction!.OsmpCode.Should().Be("0");
            transaction.Status.Should().Be("success");
        }
    }

    [Fact]
    public async Task Pay_ThirdRequestAfterTimeoutRetry_ReturnsDuplicate()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_TIMEOUT_002&account=TIMEOUT&sum=100&prv_id=100001";

        // Act - First request (timeout), Second request (success), Third request (duplicate)
        await _client.GetAsync(url);
        await _client.GetAsync(url);
        var response3 = await _client.GetAsync(url);

        // Assert
        var content = await response3.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(0);
        comment.Should().Contain("Duplicate");
        comment.Should().NotContain("Timeout retry", "third request should not retry provider");
    }

    [Fact]
    public async Task Pay_WithoutTxnId_ReturnsMissingTxnId()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&account=123456&sum=100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(300);
        comment.Should().Contain("Missing txn_id");
    }

    [Fact]
    public async Task Pay_WithZeroSum_ReturnsInvalidSum()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_ZERO&account=123456&sum=0&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        var result = int.Parse(xml.Root!.Element("result")!.Value);
        var comment = xml.Root.Element("comment")!.Value;

        result.Should().Be(301);
        comment.Should().Contain("Invalid sum");
    }

    [Fact]
    public async Task Pay_WithNegativeSum_ReturnsInvalidSum()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_NEG&account=123456&sum=-100&prv_id=100001";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        var result = int.Parse(xml.Root!.Element("result")!.Value);

        result.Should().Be(301);
    }

    [Fact]
    public async Task Pay_WithPayTypeAndExtraData_StoresCorrectly()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_EXTRA_001&account=123456&sum=250&prv_id=100001&pay_type=card&custom_field=value123&merchant_id=ABC";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var content = await response.Content.ReadAsStringAsync();
        var xml = XDocument.Parse(content);
        var result = int.Parse(xml.Root!.Element("result")!.Value);

        result.Should().Be(0);

        // Verify database
        using var db = GetDbContext();
        var transaction = db.Transactions.FirstOrDefault(t => t.TxnId == "PAY_EXTRA_001");
        transaction.Should().NotBeNull();
        transaction!.PayType.Should().Be("card");
        transaction.ExtraData.Should().NotBeNullOrEmpty();
        transaction.ExtraData.Should().Contain("custom_field");
        transaction.ExtraData.Should().Contain("value123");
        transaction.ExtraData.Should().Contain("merchant_id");
        transaction.ExtraData.Should().Contain("ABC");
    }

    [Fact]
    public async Task Pay_WithOnlyPayType_StoresPayTypeWithoutExtraData()
    {
        // Arrange
        var url = "/payment_app.cgi?command=pay&txn_id=PAY_TYPE_001&account=123456&sum=100&prv_id=100001&pay_type=cash";

        // Act
        var response = await _client.GetAsync(url);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Verify database
        using var db = GetDbContext();
        var transaction = db.Transactions.FirstOrDefault(t => t.TxnId == "PAY_TYPE_001");
        transaction.Should().NotBeNull();
        transaction!.PayType.Should().Be("cash");
        transaction.ExtraData.Should().BeNullOrEmpty();
    }
}
