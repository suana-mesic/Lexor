
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

        // Closing yesterday's leaves is daily housekeeping, not something that must happen the
        // second the container starts. On a brand-new database the API is still applying
        // migrations at that moment, so a short head start lets it finish first and keeps the
        // startup log clean; the retry below still covers a slower-than-usual start.
        private static readonly TimeSpan StartupGracePeriod = TimeSpan.FromSeconds(45);

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                await Task.Delay(StartupGracePeriod, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                return; // shutting down before the first pass
            }

            using var time = new PeriodicTimer(TimeSpan.FromHours(24));
            do
            {
                try
                {
                    // On a brand-new database the API is still applying migrations and seeding
                    // when this worker first runs, so the tables may not exist yet. Retrying with
                    // backoff (up to ~2 minutes) covers that window — without it the first pass
                    // would fail and the next attempt would only come 24 hours later.
                    await RetryPolicy.ExecuteWithBackoffAsync(async () =>
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
                    }, _logger, "Završavanje isteklih odsustava", maxAttempts: 8);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Greška pri završavanju odsustava");
                }
            } while (await time.WaitForNextTickAsync(stoppingToken));
        }
    }
}
