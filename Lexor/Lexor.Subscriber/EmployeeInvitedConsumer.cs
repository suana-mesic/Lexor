
using EasyNetQ;
using Lexor.Model;

namespace Lexor.Subscriber
{
    public class EmployeeInvitedConsumer : BackgroundService
    {
        private readonly IBus _bus;
        private readonly ILogger<EmployeeInvitedConsumer> _logger;
        private readonly IEmailSender _emailSender;


        public EmployeeInvitedConsumer(IBus bus, ILogger<EmployeeInvitedConsumer> logger, IEmailSender emailSender)
        {
            _bus = bus;
            _logger = logger;
            _emailSender = emailSender;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await _bus.PubSub.SubscribeAsync<EmployeeInvited>(
               subscriptionId: "lexor-employee-invited",
               onMessage: HandleAsync,
               cancellationToken: stoppingToken
           );
        }

        private async Task HandleAsync(EmployeeInvited message)
        {
            await RetryPolicy.ExecuteWithBackoffAsync(async () =>
            {
                const string subject = "Dobrodošli u Lexor — aktivirajte svoj nalog";
                var body = BuildBody(message.FullName, message.Username, message.InvitationCode);
                await _emailSender.SendAsync(message.Email, subject, body);
            }, _logger, $"Slanje pozivnice na {message.Email}");

            _logger.LogInformation("Pozivnica poslana na {Email}.", message.Email);
        }

        private static string BuildBody(string fullName, string username, string code) =>
            $@"<p>Poštovani/a {fullName},</p>
            <p>Za vas je kreiran nalog u <b>Lexor HR</b> aplikaciji.</p>
            <p>Vaše korisničko ime za prijavu je: <b>{username}</b></p>
            <p>Vaš aktivacijski kod je:</p>
            <p style=""font-size:22px; font-weight:bold; letter-spacing:2px;"">{code}</p>
            <p>Otvorite aplikaciju, idite na <b>Aktivacija naloga</b> i unesite svoj email, ovaj kod i novu lozinku.</p>
            <p>Za prijavu možete koristiti svoje korisničko ime ili email.</p>
            <p>Srdačan pozdrav,<br/>Lexor HR</p>";
    }
}
