namespace Lexor.Model.Responses
{
    // Current user's account (works for both admin and employee).
    public class AccountResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? ProfileImageBase64 { get; set; }
    }
}
