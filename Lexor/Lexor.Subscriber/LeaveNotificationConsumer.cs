using EasyNetQ;
using Lexor.Model;
using Lexor.Model.Enums;
using Lexor.Services.Database;
using Lexor.Services.StateMachine.LeaveStateMachine;

namespace Lexor.Subscriber
{
    public class LeaveNotificationConsumer : BackgroundService
    {
        private readonly IBus _bus;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<LeaveNotificationConsumer> _logger;

        public LeaveNotificationConsumer(IBus bus, IServiceScopeFactory scopeFactory, ILogger<LeaveNotificationConsumer> logger)
        {
            _bus = bus;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await BusSubscription.SubscribeWithRetryAsync<LeaveStatusChanged>(
                _bus, "lexor-leave-notifications", GetHandleAsync, _logger, stoppingToken);
        }

        private async Task GetHandleAsync(LeaveStatusChanged message)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<LexorDbContext>();

            var (type, title, body) = message.NewState switch
            {
                nameof(ApprovedLeaveState) => (
                NotificationType.LeaveApproved,
                "Odsustvo odobreno",
                "Vaš zahtjev za odsustvo je odobren"),
                nameof(RejectedLeaveState) => (
                NotificationType.LeaveRejected,
                "Odsustvo odbijeno",
                $"Vaš zahtjev za odsustvo je odbijen. Razlog: {message.RejectionReason}"),
                nameof(CancelledLeaveState) => (
                NotificationType.LeaveCancelled,
                "Odsustvo poništeno",
                $"Vaš zahtjev za odsustvo je poništen.{(string.IsNullOrWhiteSpace(message.RejectionReason) ? "" : $" Razlog: {message.RejectionReason}")}"),
                _ => (NotificationType.General,
                "Promjena statusa odsustva",
                "Status vašeg odsustva je promijenjen.")
            };

            db.Notifications.Add(new Notification
            {
                EmployeeId = message.EmployeeId,
                Title = title,
                Body = body,
                NotificationType = type,
                RelatedEntityType = RelatedEntityType.Leave,
                RelatedEntityId = message.LeaveId
            });

            await RetryPolicy.ExecuteWithBackoffAsync(async () =>
            {
                await db.SaveChangesAsync();

            }, _logger, $"Kreiranje notifikacije za odsustvo {message.LeaveId} {message.NewState}");

            _logger.LogInformation("Kreirana notifikacija za odsustvo {LeaveId} ({State}).", message.LeaveId, message.NewState);
        }
    }
}
