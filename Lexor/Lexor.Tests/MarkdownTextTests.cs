using Lexor.Services.Helpers;
using Xunit;

namespace Lexor.Tests
{
    /// <summary>
    /// The chatbot bubble renders plain text, so the model's markdown has to be stripped before
    /// it reaches the client. These cases pin down both halves of that: formatting is removed,
    /// and asterisks that are not formatting are left alone.
    /// </summary>
    public class MarkdownTextTests
    {
        [Theory]
        // Bold and italic markers disappear, the words stay.
        [InlineData("Prekovremeni rad **nije dozvoljen** trudnicama.",
                    "Prekovremeni rad nije dozvoljen trudnicama.")]
        [InlineData("Ovo je *kurziv* u rečenici.", "Ovo je kurziv u rečenici.")]
        [InlineData("Tekst sa __podvučenim__ dijelom.", "Tekst sa podvučenim dijelom.")]
        // Headings lose their hashes.
        [InlineData("## Godišnji odmor", "Godišnji odmor")]
        // Plain text is returned untouched.
        [InlineData("Obračun: 5 * 3 = 15 sati.", "Obračun: 5 * 3 = 15 sati.")]
        // A trailing asterisk used as a footnote mark is not formatting.
        [InlineData("Član 5.* vidi fusnotu", "Član 5.* vidi fusnotu")]
        public void ToPlainText_RemovesFormatting_ButKeepsOrdinaryAsterisks(string input, string expected)
        {
            Assert.Equal(expected, MarkdownText.ToPlainText(input));
        }

        [Fact]
        public void ToPlainText_ConvertsMarkdownBulletsToDots()
        {
            var input = "- prvi uslov\n- drugi uslov\n* treći uslov";
            var expected = "• prvi uslov\n• drugi uslov\n• treći uslov";

            Assert.Equal(expected, MarkdownText.ToPlainText(input));
        }

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData("   ")]
        public void ToPlainText_ReturnsEmpty_ForMissingText(string? input)
        {
            Assert.Equal(string.Empty, MarkdownText.ToPlainText(input!));
        }
    }
}
