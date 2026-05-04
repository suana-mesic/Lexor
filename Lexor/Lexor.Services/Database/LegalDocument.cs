using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class LegalDocument
    {
        [Key]
        public int Id { get; set; }

        public int CategoryId { get; set; }

        [ForeignKey("CategoryId")]
        public LegalDocumentCategory Category { get; set; } = null!;

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string FileBase64 { get; set; } = string.Empty;

        public long FileSize { get; set; }

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        public int UploadedByAdminId { get; set; }

        [ForeignKey("UploadedByAdminId")]
        public User UploadedByAdmin { get; set; } = null!;

        public bool IsActive { get; set; } = true;

        public ICollection<LegalDocumentChunk> Chunks { get; set; } = new List<LegalDocumentChunk>();
    }
}
