namespace Lexor.Model
{
    public class PasswordResetRequested
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}