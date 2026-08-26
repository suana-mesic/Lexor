using FluentValidation;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Formats.Webp;

namespace Lexor.Services.Helpers
{
    /// <summary>
    /// Gatekeeper for every base64 picture the API accepts (profile photos, announcement images).
    /// The file name and any client-supplied content type are ignored on purpose: the format is
    /// decided by inspecting the bytes themselves, so a renamed executable or a PDF cannot be
    /// stored as somebody's "photo".
    /// </summary>
    public static class ImageValidation
    {
        // 5 MB of actual image bytes. Phone cameras produce 2-4 MB, so this leaves headroom
        // without letting a single row bloat the database.
        private const int MaxBytes = 5 * 1024 * 1024;

        // Only formats every client here can render. WEBP is included because Android's image
        // picker hands it back for some gallery entries.
        private static readonly string[] AllowedMimeTypes =
        {
            JpegFormat.Instance.DefaultMimeType,
            PngFormat.Instance.DefaultMimeType,
            WebpFormat.Instance.DefaultMimeType,
        };

        /// <summary>
        /// Returns null when the payload is a real image of an accepted type, otherwise the
        /// message to show the user. Null or empty input means "no picture supplied", which is
        /// allowed - the caller decides whether that is acceptable.
        /// </summary>
        public static string? Validate(string? imageBase64, string fieldLabel)
        {
            if (string.IsNullOrWhiteSpace(imageBase64))
                return null;

            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(imageBase64);
            }
            catch (FormatException)
            {
                return $"{fieldLabel} nije ispravno kodirana slika.";
            }

            if (bytes.Length > MaxBytes)
                return $"{fieldLabel} je prevelika. Maksimalna veličina je {MaxBytes / (1024 * 1024)} MB.";

            // Decoding, not just sniffing: Image.Identify reads only the format signature, so a
            // couple of forged magic bytes followed by arbitrary data would satisfy it. A full
            // decode is the only check that proves the payload really is the image it claims,
            // and it costs no more than the thumbnail step that follows anyway.
            string? mimeType;
            try
            {
                using var image = Image.Load(bytes);
                mimeType = image.Metadata.DecodedImageFormat?.DefaultMimeType;
            }
            catch (Exception)
            {
                // Deliberately broad. The decoder raises documented image exceptions for most
                // malformed input, but a truncated file with a valid header can also make it
                // fail in other ways (a truncated JPEG throws NullReferenceException). The
                // question being asked is only "does this decode as an image", and every
                // failure answers no - so none of them may reach the caller as a 500.
                return $"{fieldLabel} nije prepoznata kao slika. Dozvoljeni formati: JPG, PNG i WEBP.";
            }

            if (mimeType == null || !AllowedMimeTypes.Contains(mimeType))
                return $"{fieldLabel} mora biti u JPG, PNG ili WEBP formatu.";

            return null;
        }
    }

    public static class ImageValidationRules
    {
        /// <summary>
        /// Rejects a base64 property that is not a genuine JPG/PNG/WEBP image within the size
        /// limit. Uses Custom so the failure message can name the actual reason (wrong format,
        /// too large, corrupt) instead of one catch-all sentence.
        /// </summary>
        public static void ValidImage<T>(
            this IRuleBuilderInitial<T, string?> rule, string fieldLabel)
        {
            rule.Custom((value, context) =>
            {
                var error = ImageValidation.Validate(value, fieldLabel);
                if (error != null)
                    context.AddFailure(error);
            });
        }
    }
}
