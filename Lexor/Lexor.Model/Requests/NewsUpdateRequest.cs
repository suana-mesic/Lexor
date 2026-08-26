namespace Lexor.Model.Requests
{
    public class NewsUpdateRequest
    {
        public string? Title { get; set; }
        public string? Content { get; set; }

        /// <summary>
        /// A new picture. Null means "leave the current one alone" - to actually clear it,
        /// set <see cref="RemoveImage"/>, because a null cannot express the difference.
        /// </summary>
        public string? ImageBase64 { get; set; }

        public bool RemoveImage { get; set; }
    }
}
