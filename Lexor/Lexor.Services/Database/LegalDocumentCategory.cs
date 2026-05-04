using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Lexor.Services.Database
{
    public class LegalDocumentCategory
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        public ICollection<LegalDocument> LegalDocuments { get; set; } = new List<LegalDocument>();
    }
}
