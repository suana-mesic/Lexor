using Lexor.Services.Database;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
namespace Lexor.Tests;

public class ApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Marks this host as a test host so startup migrations/seeding are skipped.
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            // Minimal config so the host passes ValidateOnStart and boots for tests.
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["JwtToken:SecretKey"] = "test-secret-key-that-is-long-enough-32b",
                ["JwtToken:Issuer"] = "LexorTests",
                ["JwtToken:Audience"] = "LexorTests",
                ["Groq:ApiKey"] = "test-groq-key",
                ["ConnectionStrings:DefaultConnection"] = "Server=localhost;Database=LexorTests;",
                ["RabbitMQ:ConnectionString"] = "host=localhost",
            });
        });

        builder.ConfigureServices(services =>
        {
            // Swap SQL Server for an in-memory database, isolated in its own EF service
            // provider so it doesn't clash with the app's SQL Server provider registration.
            services.RemoveAll(typeof(DbContextOptions<LexorDbContext>));

            var inMemoryProvider = new ServiceCollection()
                .AddEntityFrameworkInMemoryDatabase()
                .BuildServiceProvider();

            services.AddDbContext<LexorDbContext>(options =>
                options.UseInMemoryDatabase("LexorTests")
                       .UseInternalServiceProvider(inMemoryProvider));
        });
    }
}