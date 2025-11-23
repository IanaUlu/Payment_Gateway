# QiwiGateway Tests

## ?? Overview

This test project contains comprehensive Unit and Integration tests for the QiwiGateway API.

## ?? Test Structure

```
QiwiGateway.Tests/
??? UnitTests/
?   ??? TestErrorCodeMapperTests.cs     # Tests for error code mapping
?   ??? TestProtocolTests.cs            # Tests for TestProtocol logic
??? IntegrationTests/
    ??? QiwiGatewayWebApplicationFactory.cs  # Test server setup
    ??? CheckCommandIntegrationTests.cs      # CHECK command tests
    ??? PayCommandIntegrationTests.cs        # PAY command tests (includes timeout retry)
```

## ?? Running Tests

### Run all tests:
```bash
dotnet test
```

### Run specific test class:
```bash
dotnet test --filter "FullyQualifiedName~CheckCommandIntegrationTests"
dotnet test --filter "FullyQualifiedName~PayCommandIntegrationTests"
dotnet test --filter "FullyQualifiedName~TestProtocolTests"
```

### Run with detailed output:
```bash
dotnet test --logger "console;verbosity=detailed"
```

### Generate coverage report (requires coverlet):
```bash
dotnet test /p:CollectCoverage=true /p:CoverletOutputFormat=opencover
```

## ?? Test Coverage

### Unit Tests (11 tests)
- ? **TestErrorCodeMapper** (7 tests)
  - Map success code (2 ? 0)
  - Map timeout codes (3 ? 1, 1 ? 300)
  - Map account not found (99 ? 79)
  - Map unknown codes to default (13)
  - Theory test with multiple scenarios

- ? **TestProtocol** (11 tests)
  - CHECK command with valid/invalid accounts
  - PAY command with valid/invalid accounts
  - PAY with zero/negative sums
  - Unknown command handling
  - Timeout account simulation
  - Response logging verification

### Integration Tests (21 tests)
- ? **CHECK Command** (6 tests)
  - Valid account ? success
  - Invalid account ? error 79
  - Without txn_id (allowed)
  - With zero sum (allowed)
  - Without account ? error 302
  - Invalid provider ? error 5

- ? **PAY Command** (15 tests)
  - First successful payment
  - Duplicate successful payment
  - Invalid account (creates failed transaction)
  - Duplicate error transaction
  - **Timeout retry scenario** (CRITICAL!)
    - First request ? timeout (code 1, status='timeout')
    - Second request ? success (code 0, status='success')
    - Third request ? duplicate (no provider call)
  - Without txn_id ? error 300
  - With zero sum ? error 301
  - With negative sum ? error 301
  - With PayType and ExtraData
  - With only PayType

## ? Key Test Scenarios

### 1. Timeout Retry Logic
```csharp
// First request
GET /payment_app.cgi?command=pay&txn_id=PAY_TIMEOUT_001&account=TIMEOUT&sum=100&prv_id=100001
Response: result=1 (timeout)
Database: OsmpCode="1", Status="timeout"

// Second request (same txn_id)
GET /payment_app.cgi?command=pay&txn_id=PAY_TIMEOUT_001&account=TIMEOUT&sum=100&prv_id=100001
Response: result=0 (success), comment="Timeout retry..."
Database: OsmpCode="0", Status="success" (updated)
Provider: CALLED AGAIN ?

// Third request (same txn_id)
GET /payment_app.cgi?command=pay&txn_id=PAY_TIMEOUT_001&account=TIMEOUT&sum=100&prv_id=100001
Response: result=0, comment="Duplicate..."
Provider: NOT CALLED ?
```

### 2. Duplicate Handling
```csharp
// First request
Response: result=0, BePayTxnId=251122123456789
Database: Created

// Second request (duplicate)
Response: result=0, comment="Duplicate txn_id=... Previous result=0. BePayTxnId=251122123456789"
Provider: NOT CALLED ?
```

### 3. Validation Tests
- Missing txn_id (PAY only) ? 300
- Missing account (all commands) ? 302
- Invalid sum (PAY only) ? 301
- Unknown provider ? 5

## ?? Assertions

Tests use **FluentAssertions** for readable assertions:

```csharp
result.Should().Be(0, "valid account should return success");
transaction.Status.Should().Be("timeout", "timeout status should be 'timeout', not 'failed'");
comment.Should().Contain("Timeout retry");
```

## ?? Dependencies

- **xUnit** - Test framework
- **FluentAssertions** - Fluent assertion library
- **Microsoft.AspNetCore.Mvc.Testing** - Integration testing
- **Microsoft.EntityFrameworkCore.InMemory** - In-memory database for tests

## ??? CI/CD Integration

Add to your CI/CD pipeline:

```yaml
# .github/workflows/dotnet.yml
- name: Run tests
  run: dotnet test --no-build --verbosity normal --logger "trx;LogFileName=test-results.trx"
  
- name: Publish test results
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: test-results
    path: '**/TestResults/*.trx'
```

## ?? Expected Results

All 32 tests should **PASS**:
- 11 Unit tests
- 21 Integration tests

## ?? Notes

- Integration tests use **InMemory database** (isolated, no PostgreSQL required)
- Each test is **independent** (no shared state)
- Tests verify **both HTTP responses and database state**
- Special test account `"TIMEOUT"` simulates timeout ? success scenario

## ?? Critical Tests

These tests verify the core business logic:

1. ? `Pay_TimeoutRetry_FirstRequestTimeout_SecondRequestSuccess`
   - Ensures timeout retry works correctly
   - Verifies status is "timeout" (not "failed")
   - Confirms provider is called again on retry

2. ? `Pay_DuplicateSuccessfulPayment_ReturnsDuplicateMessage`
   - Ensures idempotency
   - Confirms provider is NOT called for duplicates

3. ? `Pay_WithPayTypeAndExtraData_StoresCorrectly`
   - Verifies extra data handling
   - Confirms JSON serialization works

---

**Happy Testing!** ??
