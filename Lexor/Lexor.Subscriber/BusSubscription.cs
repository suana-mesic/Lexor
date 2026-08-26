using EasyNetQ;

namespace Lexor.Subscriber
{
    /// <summary>
    /// Subscribing to RabbitMQ is the first thing every consumer does, and on a cold start the
    /// broker may still be booting. EasyNetQ throws in that case, which would take the whole
    /// worker host down (BackgroundService exceptions are fatal by default). Retrying here keeps
    /// the worker alive until the broker answers — a second line of defence behind the
    /// healthcheck in docker-compose.
    /// </summary>
    public static class BusSubscription
    {
        private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(5);

        public static async Task SubscribeWithRetryAsync<TMessage>(
            IBus bus,
            string subscriptionId,
            Func<TMessage, Task> onMessage,
            ILogger logger,
            CancellationToken stoppingToken)
        {
            var attempt = 0;

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await bus.PubSub.SubscribeAsync(subscriptionId, onMessage, stoppingToken);
                    if (attempt > 0)
                        logger.LogInformation("Pretplata {SubscriptionId} uspostavljena.", subscriptionId);
                    return;
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    return; // shutting down
                }
                catch (Exception ex)
                {
                    attempt++;
                    logger.LogWarning(
                        "Pretplata {SubscriptionId} nije uspjela (pokušaj {Attempt}). Ponovni pokušaj za {Delay}s. Razlog: {Reason}",
                        subscriptionId, attempt, RetryDelay.TotalSeconds, ex.Message);

                    try
                    {
                        await Task.Delay(RetryDelay, stoppingToken);
                    }
                    catch (OperationCanceledException)
                    {
                        return;
                    }
                }
            }
        }
    }
}
