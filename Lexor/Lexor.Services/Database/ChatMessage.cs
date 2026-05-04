using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Lexor.Model.Enums;

namespace Lexor.Services.Database
{
    public class ChatMessage
    {
        [Key]
        public int Id { get; set; }

        public int ChatConversationId { get; set; }

        [ForeignKey("ChatConversationId")]
        public ChatConversation ChatConversation { get; set; } = null!;

        public ChatMessageRole Role { get; set; }

        [Required]
        public string Content { get; set; } = string.Empty;

        public string? Citations { get; set; }

        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }
}
