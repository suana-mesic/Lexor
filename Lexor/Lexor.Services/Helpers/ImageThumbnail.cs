using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Processing;

namespace Lexor.Services.Helpers
{
    /// <summary>
    /// Builds the small square avatar shown next to a name in list views.
    /// List endpoints must not carry full-size images (guideline 8.2), but list views must
    /// still show a picture (guideline 6) — so the full image is stored once and this
    /// downscaled copy is what the lists return.
    /// </summary>
    public static class ImageThumbnail
    {
        private const int SizePx = 96;      // enough for a 48pt avatar on a hi-dpi screen
        private const int JpegQuality = 75; // ~3-5 KB per thumbnail

        /// <summary>
        /// Returns a 96x96 JPEG thumbnail as base64, or null when the input is empty or
        /// not a decodable image. Never throws: a bad upload must not break saving the user.
        /// </summary>
        public static string? Create(string? imageBase64)
        {
            if (string.IsNullOrWhiteSpace(imageBase64))
                return null;

            try
            {
                var bytes = Convert.FromBase64String(imageBase64);
                using var image = Image.Load(bytes);

                // Crop-to-fill rather than letterbox, so the avatar circle is never padded.
                image.Mutate(x => x.Resize(new ResizeOptions
                {
                    Size = new Size(SizePx, SizePx),
                    Mode = ResizeMode.Crop
                }));

                using var output = new MemoryStream();
                image.Save(output, new JpegEncoder { Quality = JpegQuality });
                return Convert.ToBase64String(output.ToArray());
            }
            catch
            {
                // Unreadable or non-image payload — the UI falls back to initials.
                return null;
            }
        }
    }
}
