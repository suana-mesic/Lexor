using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Lexor.Services.Database
{
    public class LegalDocumentChunk
    {
        [Key]
        public int Id { get; set; }

        public int LegalDocumentId { get; set; }

        [ForeignKey("LegalDocumentId")]
        public LegalDocument LegalDocument { get; set; } = null!;

        public int ChunkIndex { get; set; }

        [Required]
        public string ChunkText { get; set; } = string.Empty;

        public string? EmbeddingJson { get; set; }
    }
}
