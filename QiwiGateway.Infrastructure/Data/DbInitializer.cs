using QiwiGateway.Domain.Entities;

namespace QiwiGateway.Infrastructure.Data;

public static class DbInitializer
{
    public static void Seed(QiwiDbContext context)
    {
        Console.WriteLine("🔄 Seeding test data into qiwi_gateway...");

        if (!context.Providers.Any())
        {
            Console.WriteLine("→ Adding test provider...");
            context.Providers.Add(new Provider { Id = 1, Name = "QIWI", Code = "qiwi" });
        }

        if (!context.Accounts.Any())
        {
            Console.WriteLine("→ Adding test account...");
            context.Accounts.Add(new Account { Id = 1, AccountNumber = "79001234567" });
        }

        if (!context.Transactions.Any())
        {
            Console.WriteLine("→ Adding test transaction...");
            context.Transactions.Add(new Transaction
            {
                BePayTxnId = GenerateTransactionId(),
                PrvId = 1,
                TxnId = "TXN123456",
                AccountNumber = "79001234567",
                Amount = 100.50m,
                Status = "pending",
                OsmpCode = "0",  // Success code
                CreatedAt = DateTime.UtcNow
            });
        }

        context.SaveChanges();
        Console.WriteLine("✅ Seeding complete.");
    }

    private static string GenerateTransactionId()
    {
        var timestamp = DateTime.UtcNow.ToString("yyMMddHHmmss");
        var random = Random.Shared.Next(100, 999);
        return $"{timestamp}{random}";
    }
}