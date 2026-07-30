namespace Lexor.Subscriber
{
    public static class RetryPolicy
    {
        // Runs the action, retrying with exponential backoff (1s, 2s, 4s, 8s...).
        // Logs every failed attempt; rethrows after the last one so EasyNetQ can move the
        // message to its error queue instead of losing it silently.
        public static async Task ExecuteWithBackoffAsync(
           Func<Task> action,
           ILogger logger,
           string operation,
           int maxAttempts = 4)
        {
            for (var attempt = 1; ; attempt++)
            {
                try
                {
                    await action();
                    return;
                }
                catch (Exception ex) when (attempt < maxAttempts)
                {
                    var delay = TimeSpan.FromSeconds(Math.Pow(2, attempt - 1));
                    logger.LogWarning(ex,
                      "{Operation} nije uspjela (pokušaj {Attempt}/{Max}). Ponovni pokušaj za {Delay}s.",
                      operation, attempt, maxAttempts, delay.TotalSeconds);
                    await Task.Delay(delay);
                }
                catch (Exception ex)
                {
                    logger.LogError(ex,
                        "{Operation} neuspješna nakon {Max} pokušaja.", operation, maxAttempts);
                    throw;
                }
            }
        }
    }
}
