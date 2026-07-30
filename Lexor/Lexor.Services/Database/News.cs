using System.ComponentModel.DataAnnotations;

namespace Lexor.Services.Database
{
    // Company announcement shown to employees on the mobile home screen and managed by
    // the admin in the desktop app.
    public class News
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(4000)]
        public string Content { get; set; } = string.Empty;

        public string? ImageBase64 { get; set; }

        public DateTime PublishedAt { get; set; } = DateTime.UtcNow;
    }
}
