using EasyNetQ;
using Lexor.Model;
using Lexor.Model.Enums;
using Lexor.Services.Database;
using Lexor.Services.StateMachine.SalarySlipStateMachine;

namespace Lexor.Subscriber
{
    /// <summary>
    /// Turns payslip state changes into employee notifications, so the employee is told when
    /// their payslip is approved and when it is actually paid out — not just about leave.
    /// </summary>
    public class SalarySlipNotificationConsumer : BackgroundService
    {
        private readonly IBus _bus;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SalarySlipNotificationConsumer> _logger;

        public SalarySlipNotificationConsumer(
            IBus bus,
            IServiceScopeFactory scopeFactory,
            ILogger<SalarySlipNotificationConsumer> logger)
        {
            _bus = bus;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await BusSubscription.SubscribeWithRetryAsync<SalarySlipStatusChanged>(
                _bus, "lexor-salaryslip-notifications", GetHandleAsync, _logger, stoppingToken);
        }

        private async Task GetHandleAsync(SalarySlipStatusChanged message)
        {
            using var scope = _scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<LexorDbContext>();

            var period = message.Period;

            var (type, title, body) = message.NewState switch
            {
                nameof(ApprovedSalarySlipState) => (
                    NotificationType.SalarySlipApproved,
                    "Platna lista odobrena",
                    $"Vaša platna lista za {period} je odobrena."),
                nameof(PaidSalarySlipState) => (
                    NotificationType.SalarySlipPaid,
                    "Plata isplaćena",
                    $"Vaša plata za {period} je isplaćena."),
                _ => (
                    NotificationType.General,
                    "Promjena statusa platne liste",
                    $"Status vaše platne liste za {period} je promijenjen.")
            };

            db.Notifications.Add(new Notification
            {
                EmployeeId = message.EmployeeId,
                Title = title,
                Body = body,
                NotificationType = type,
                RelatedEntityType = RelatedEntityType.SalarySlip,
                RelatedEntityId = message.SalarySlipId
            });

            await RetryPolicy.ExecuteWithBackoffAsync(
                async () => await db.SaveChangesAsync(),
                _logger,
                $"Kreiranje notifikacije za platnu listu {message.SalarySlipId} {message.NewState}");

            _logger.LogInformation(
                "Kreirana notifikacija za platnu listu {SalarySlipId} ({State}).",
                message.SalarySlipId, message.NewState);
        }
    }
}
