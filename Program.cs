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
//using QiwiGateway.Application.Protocols.Mobile;
//using QiwiGateway.Application.Protocols.Aggregators;

var builder = WebApplication.CreateBuilder(args);

// Подключение базы данных
builder.Services.AddDbContext<QiwiDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Подключение MediatR
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(CreateTransactionCommand).Assembly));

//
builder.WebHost.UseUrls("http://0.0.0.0:5000");

// Контроллеры + поддержка XML
builder.Services.AddControllers()
    .AddXmlSerializerFormatters();

// Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "QiwiGateway API", Version = "v1" });
});

// Логгер
builder.Services.AddScoped<LogWriter>();
builder.Services.AddScoped<ILogWriter>(sp => sp.GetRequiredService<LogWriter>());
builder.Services.AddScoped<IApiLogWriter>(sp => sp.GetRequiredService<LogWriter>());

// Регистрация всех провайдеров
builder.Services.AddScoped<TestErrorCodeMapper>();
builder.Services.AddScoped<TestProtocol>();
//builder.Services.AddScoped<MobileProtocol>();
//builder.Services.AddScoped<AggregatorProtocol>();

// Резолвер провайдеров
builder.Services.AddScoped<ProviderResolver>();

builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.SuppressModelStateInvalidFilter = true;
});

var app = builder.Build();

// Swagger UI
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Поддержка прокси/балансировщиков
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

// Маршрутизация
app.MapControllers();

// Инициализация базы данных
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<QiwiDbContext>();
    DbInitializer.Seed(db);
}

// Тестовый endpoint
var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        )).ToArray();

    return forecast;
})
.WithName("GetWeatherForecast");

app.Run();

// Вспомогательная модель
record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}