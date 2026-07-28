using System.ComponentModel.DataAnnotations;

namespace Lexor.Services.Database
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(50)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Username { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;

        public string PasswordSalt { get; set; } = string.Empty;

        [Phone]
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }

        public string? ProfileImageBase64 { get; set; }

        public bool IsActive { get; set; } = true;

        [MaxLength(20)]
        public string? InvitationCode { get; set; }

        public bool IsCodeActivated { get; set; } = false;

        public string? PasswordResetCodeHash { get; set; }

        public string? PasswordResetCodeSalt { get; set; }

        public DateTime? PasswordResetExpiresAt { get; set; }

        public int PasswordResetAttempts { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? LastLoginAt { get; set; }

        public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

        public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

        public Employee? Employee { get; set; }
    }
}
