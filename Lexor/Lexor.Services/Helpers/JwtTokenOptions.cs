namespace Lexor.Services.Helpers
{
    public class JwtTokenOptions
    {
        public const int DefaultDurationInMinutes = 30;
        public const int DefaultRefreshTokenDurationInDays = 7;

        public string Issuer { get; set; } = string.Empty;
        public string Audience { get; set; } = string.Empty;
        public string SecretKey { get; set; } = string.Empty;
        public int DurationInMinutes { get; set; } = DefaultDurationInMinutes;
        public int RefreshTokenDurationInDays { get; set; } = DefaultRefreshTokenDurationInDays;
    }
}
