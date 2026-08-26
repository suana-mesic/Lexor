using EasyNetQ;
using Lexor.Model;

namespace Lexor.Subscriber
{
    public class PasswordResetConsumer : BackgroundService
    {
        private readonly IBus _bus;
        private readonly IEmailSender _emailSender;
        private readonly ILogger<PasswordResetConsumer> _logger;

        public PasswordResetConsumer(IBus bus, IEmailSender emailSender, ILogger<PasswordResetConsumer> logger)
        {
            _bus = bus;
            _emailSender = emailSender;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await BusSubscription.SubscribeWithRetryAsync<PasswordResetRequested>(
                _bus, "lexor-password-reset", HandleAsync, _logger, stoppingToken);
        }

        private async Task HandleAsync(PasswordResetRequested message)
        {
            await RetryPolicy.ExecuteWithBackoffAsync(async () =>
            {
                const string subject = "Lexor — kod za resetovanje lozinke";
                var body = BuildBody(message.FullName, message.Code);
                await _emailSender.SendAsync(message.Email, subject, body);
            }, _logger, $"Slanje reset koda na {message.Email}");

            _logger.LogInformation("Kod za reset lozinke poslan na {Email}.", message.Email);
        }

        private static string BuildBody(string fullName, string code) =>
            $@"<p>Poštovani/a {fullName},</p>
            <p>Zatražili ste resetovanje lozinke za Lexor nalog.</p>
            <p>Vaš kod je:</p>
            <p style=""font-size:22px; font-weight:bold; letter-spacing:2px;"">{code}</p>
            <p>Kod vrijedi 30 minuta. Ako niste vi zatražili reset, ignorišite ovaj email.</p>
            <p>Srdačan pozdrav,<br/>Lexor HR</p>";
    }
}
