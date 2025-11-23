using Microsoft.EntityFrameworkCore;
using QiwiGateway.Domain.Entities;

namespace QiwiGateway.Infrastructure.Data;

public class QiwiDbContext : DbContext
{
    public QiwiDbContext(DbContextOptions<QiwiDbContext> options) : base(options) { }

    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<Provider> Providers => Set<Provider>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
       
        modelBuilder.Entity<Transaction>()
            .HasKey(t => t.BePayTxnId);

        //  Уникальный индекс по PrvId + TxnId
        modelBuilder.Entity<Transaction>()
            .HasIndex(t => new { t.PrvId, t.TxnId })
            .IsUnique();

        modelBuilder.Entity<Account>()
            .HasKey(a => a.Id);

        modelBuilder.Entity<Account>()
            .HasIndex(a => a.AccountNumber)
            .IsUnique();

        // Provider
        modelBuilder.Entity<Provider>()
            .HasKey(p => p.Id);
    }

}
