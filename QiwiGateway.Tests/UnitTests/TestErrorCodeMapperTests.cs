using FluentAssertions;
using QiwiGateway.Application.Protocols.Test;
using Xunit;

namespace QiwiGateway.Tests.UnitTests;

public class TestErrorCodeMapperTests
{
    private readonly TestErrorCodeMapper _mapper;

    public TestErrorCodeMapperTests()
    {
        _mapper = new TestErrorCodeMapper();
    }

    [Fact]
    public void Map_ShouldReturn0_WhenProviderCodeIs2()
    {
        // Arrange
        var providerCode = 2;

        // Act
        var result = _mapper.Map(providerCode);

        // Assert
        result.Should().Be(0, "provider code 2 maps to success (0)");
    }

    [Fact]
    public void Map_ShouldReturn1_WhenProviderCodeIs3()
    {
        // Arrange
        var providerCode = 3;

        // Act
        var result = _mapper.Map(providerCode);

        // Assert
        result.Should().Be(1, "provider code 3 maps to timeout (1)");
    }

    [Fact]
    public void Map_ShouldReturn300_WhenProviderCodeIs1()
    {
        // Arrange
        var providerCode = 1;

        // Act
        var result = _mapper.Map(providerCode);

        // Assert
        result.Should().Be(300, "provider code 1 maps to another timeout code (300)");
    }

    [Fact]
    public void Map_ShouldReturn79_WhenProviderCodeIs99()
    {
        // Arrange
        var providerCode = 99;

        // Act
        var result = _mapper.Map(providerCode);

        // Assert
        result.Should().Be(79, "provider code 99 maps to account not found (79)");
    }

    [Fact]
    public void Map_ShouldReturn13_ForUnknownProviderCode()
    {
        // Arrange
        var unknownCode = 42;

        // Act
        var result = _mapper.Map(unknownCode);

        // Assert
        result.Should().Be(13, "unknown provider codes default to format error (13)");
    }

    [Theory]
    [InlineData(2, 0)]    // Success
    [InlineData(3, 1)]    // Timeout
    [InlineData(1, 300)]  // Another timeout
    [InlineData(99, 79)]  // Account not found
    [InlineData(100, 13)] // Unknown ? default
    [InlineData(-1, 13)]  // Negative ? default
    public void Map_ShouldReturnCorrectCode_ForVariousProviderCodes(int providerCode, int expectedOsmpCode)
    {
        // Act
        var result = _mapper.Map(providerCode);

        // Assert
        result.Should().Be(expectedOsmpCode);
    }
}
