using EasyNetQ;
using Lexor.Model;
using Lexor.Services;

namespace Lexor.Subscriber
{
    // Listens for uploaded legal documents and indexes them (PDF text -> chunks ->
    // embeddings) in the background, off the admin's upload request.
    public class LegalDocumentIndexConsumer : BackgroundService
    {
        private readonly IBus _bus;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<LegalDocumentIndexConsumer> _logger;

        public LegalDocumentIndexConsumer(IBus bus, IServiceScopeFactory scopeFactory, ILogger<LegalDocumentIndexConsumer> logger)
        {
            _bus = bus;
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await _bus.PubSub.SubscribeAsync<LegalDocumentUploaded>(
                subscriptionId: "lexor-legal-document-index",
                onMessage: HandleAsync,
                cancellationToken: stoppingToken);
        }

        private async Task HandleAsync(LegalDocumentUploaded message)
        {
            await RetryPolicy.ExecuteWithBackoffAsync(async () =>
            {
                using var scope = _scopeFactory.CreateScope();
                var indexer = scope.ServiceProvider.GetRequiredService<ILegalDocumentIndexer>();
                await indexer.IndexAsync(message.DocumentId);
            }, _logger, $"Indeksiranje pravnog dokumenta {message.DocumentId}");

            _logger.LogInformation("Indeksiran pravni dokument {DocumentId}.", message.DocumentId);
        }
    }
}
