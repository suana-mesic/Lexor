namespace Lexor.Model.Responses
{
    public class UserResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;

        // Small avatar for the users table (guideline 6).
        public string? ProfileThumbnailBase64 { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string RoleName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public bool IsCodeActivated { get; set; }
        public DateTime? LastLoginAt { get; set; }
    }
}
