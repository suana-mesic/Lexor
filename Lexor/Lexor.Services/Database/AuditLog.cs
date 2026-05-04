using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Lexor.Model.Enums;

namespace Lexor.Services.Database
{
    public class AuditLog
    {
        [Key]
        public int Id { get; set; }

        public int AdminUserId { get; set; }

        [ForeignKey("AdminUserId")]
        public User AdminUser { get; set; } = null!;

        public AuditAction Action { get; set; }

        public AuditEntityType EntityType { get; set; }

        public int EntityId { get; set; }

        public string? OldValues { get; set; }

        public string? NewValues { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
