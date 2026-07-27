namespace Lexor.Model.Responses
{
    public class ChatMessageResponse
    {
        public int Role { get; set; }          // 1 = User, 2 = Assistant
        public string Content { get; set; } = string.Empty;
        public List<string> Sources { get; set; } = new();
        public DateTime Timestamp { get; set; }
    }
}
