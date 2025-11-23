using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using QiwiGateway.Api.Interfaces;
using QiwiGateway.Api.Services;
using QiwiGateway.Application.Logging;
using QiwiGateway.Application.Protocols;
using QiwiGateway.Application.Protocols.Test;
using QiwiGateway.Application.Transactions.Commands;
using QiwiGateway.Infrastructure.Data;


var builder = WebApplication.CreateBuilder(args);

// Database connection
builder.Services.AddDbContext<QiwiDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// MediatR setup
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(CreateTransactionCommand).Assembly));

// URL configuration
builder.WebHost.UseUrls("http://0.0.0.0:5000");

// Controllers + XML support
builder.Services.AddControllers()
    .AddXmlSerializerFormatters();

// Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "QiwiGateway API", Version = "v1" });
});

// Logger
builder.Services.AddScoped<LogWriter>();
builder.Services.AddScoped<ILogWriter>(sp => sp.GetRequiredService<LogWriter>());
builder.Services.AddScoped<IApiLogWriter>(sp => sp.GetRequiredService<LogWriter>());

// Register all providers
builder.Services.AddScoped<TestErrorCodeMapper>();
builder.Services.AddScoped<TestProtocol>();
//builder.Services.AddScoped<MobileProtocol>();
//builder.Services.AddScoped<AggregatorProtocol>();

// Provider resolver
builder.Services.AddScoped<ProviderResolver>();

builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.SuppressModelStateInvalidFilter = true;
});

var app = builder.Build();

// Swagger UI - Enabled for Development and Production (unless explicitly disabled)
// To disable in production server, set DISABLE_SWAGGER=true environment variable
var disableSwagger = app.Configuration.GetValue<bool>("DISABLE_SWAGGER", false);
if (!disableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "QiwiGateway API v1");
        c.RoutePrefix = "swagger"; // Swagger at /swagger
    });
}

// Proxy/load balancer support
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

// Routing
app.MapControllers();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// Database initialization - Run migrations automatically
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<QiwiDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    
    try
    {
        logger.LogInformation("Applying database migrations...");
        
        // Ensure database is created
        db.Database.EnsureCreated();
        
        logger.LogInformation("Database migrations applied successfully");
        
        // Seed data only in Development
        if (app.Environment.IsDevelopment() && !app.Environment.IsEnvironment("Testing"))
        {
            DbInitializer.Seed(db);
        }
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "An error occurred while migrating the database");
        throw;
    }
}

app.Run();

// Make the implicit Program class public so test projects can access it
public partial class Program { }