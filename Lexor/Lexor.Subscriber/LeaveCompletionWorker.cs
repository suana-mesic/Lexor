
using Lexor.Services.Database;
using Lexor.Services.StateMachine.LeaveStateMachine;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Subscriber
{
    public class LeaveCompletionWorker : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<LeaveCompletionWorker> _logger;

        public LeaveCompletionWorker(IServiceScopeFactory scopeFactory, ILogger<LeaveCompletionWorker> logger)
        {
            _logger = logger;
            _scopeFactory = scopeFactory;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            using var time = new PeriodicTimer(TimeSpan.FromHours(24));
            do
            {
                try
                {
                    using var scope = _scopeFactory.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<LexorDbContext>();
                    var today = DateOnly.FromDateTime(DateTime.UtcNow);

                    var count = await db.Leaves
                             .Where(l => l.State == nameof(ApprovedLeaveState) && l.DateTo < today)
                             .ExecuteUpdateAsync(s => s
                                 .SetProperty(l => l.State, nameof(CompletedLeaveState))
                                 .SetProperty(l => l.CompletedAt, DateTime.UtcNow), stoppingToken);

                    if (count > 0)
                        _logger.LogInformation("Završeno {Count} odsustava.", count);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri završavanju odsustava");
                }
            } while (await time.WaitForNextTickAsync(stoppingToken));
        }
    }
}
