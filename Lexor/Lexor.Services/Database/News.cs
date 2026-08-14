using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    // Company announcement shown to employees on the mobile home screen and managed by
    // back-office roles in the desktop app.
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

        // Author of the announcement. Nullable so pre-existing rows stay valid; a null author
        // means only an administrator may edit or delete it (see NewsService).
        public int? PublishedByUserId { get; set; }

        [ForeignKey(nameof(PublishedByUserId))]
        public User? PublishedBy { get; set; }
    }
}
