using System.Text.RegularExpressions;

namespace Lexor.Services.Helpers
{
    /// <summary>
    /// Turns a language model's markdown-formatted answer into plain text.
    /// The chat bubble renders plain text, so a leftover "**bold**" would show up as literal
    /// asterisks. The chatbot's system prompt already asks for plain text; this is the safety
    /// net for when the model formats anyway.
    /// </summary>
    public static class MarkdownText
    {
        public static string ToPlainText(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return string.Empty;

            // **bold** / __bold__ -> bold
            text = Regex.Replace(text, @"\*\*(.+?)\*\*", "$1", RegexOptions.Singleline);
            text = Regex.Replace(text, @"__(.+?)__", "$1", RegexOptions.Singleline);

            // *italic* -> italic, but only when the asterisks hug the word, so "5 * 3" and a
            // lone asterisk used as a footnote mark are left alone.
            text = Regex.Replace(text, @"(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)", "$1", RegexOptions.Singleline);

            // "# Naslov" -> "Naslov"
            text = Regex.Replace(text, @"^#{1,6}\s+", "", RegexOptions.Multiline);

            // "- stavka" / "* stavka" -> "• stavka"
            text = Regex.Replace(text, @"^\s*[-*]\s+", "• ", RegexOptions.Multiline);

            return text.Trim();
        }
    }
}
