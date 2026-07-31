namespace Lexor.Model.Requests
{
    public class AccountUpdateRequest
    {
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ProfileImageBase64 { get; set; }
    }
}
