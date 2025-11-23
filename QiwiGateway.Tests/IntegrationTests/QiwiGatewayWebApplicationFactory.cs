using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using QiwiGateway.Infrastructure.Data;

namespace QiwiGateway.Tests.IntegrationTests;

public class QiwiGatewayWebApplicationFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            // Remove the existing DbContext registration
            services.RemoveAll(typeof(DbContextOptions<QiwiDbContext>));
            services.RemoveAll(typeof(QiwiDbContext));

            // Add InMemory database for tests
            services.AddDbContext<QiwiDbContext>(options =>
            {
                options.UseInMemoryDatabase($"QiwiGatewayTestDb_{Guid.NewGuid()}");
            });
        });

        builder.UseEnvironment("Testing");
    }
}
