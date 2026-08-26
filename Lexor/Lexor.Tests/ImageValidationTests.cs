using System;
using System.IO;
using System.Text;
using Lexor.Services.Helpers;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Bmp;
using SixLabors.ImageSharp.Formats.Jpeg;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.PixelFormats;
using Xunit;

namespace Lexor.Tests
{
    /// <summary>
    /// Profile photos and announcement pictures arrive as base64 with no file name and no
    /// content type, so the only trustworthy signal is the bytes themselves. These cases pin
    /// down that a real image passes and that anything wearing an image's clothing does not.
    /// </summary>
    public class ImageValidationTests
    {
        private const string Label = "Profilna slika";

        // A real, freshly encoded image of the requested format - the bytes carry that format's
        // signature, which is exactly what the validator inspects.
        private static string EncodedImage(int width, int height, string format)
        {
            using var image = new Image<Rgba32>(width, height);
            using var output = new MemoryStream();
            switch (format)
            {
                case "png":
                    image.Save(output, new PngEncoder());
                    break;
                case "bmp":
                    image.Save(output, new BmpEncoder());
                    break;
                default:
                    image.Save(output, new JpegEncoder());
                    break;
            }
            return Convert.ToBase64String(output.ToArray());
        }

        [Theory]
        [InlineData("jpeg")]
        [InlineData("png")]
        public void AcceptsRealImageOfAllowedFormat(string format)
        {
            Assert.Null(ImageValidation.Validate(EncodedImage(32, 32, format), Label));
        }

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData("   ")]
        public void TreatsMissingPictureAsValid(string? payload)
        {
            // "No picture supplied" is a separate decision from "picture is broken"; the
            // required/optional call belongs to each request's own rules.
            Assert.Null(ImageValidation.Validate(payload, Label));
        }

        [Fact]
        public void RejectsNonImageBytesThatAreValidBase64()
        {
            // A PDF is perfectly good base64 - only the magic bytes give it away.
            var pdf = Convert.ToBase64String(Encoding.ASCII.GetBytes("%PDF-1.7\n%âãÏÓ\n"));
            var error = ImageValidation.Validate(pdf, Label);
            Assert.NotNull(error);
            Assert.Contains("nije prepoznata kao slika", error);
        }

        [Fact]
        public void RejectsWindowsExecutable()
        {
            var exe = Convert.ToBase64String(new byte[] { 0x4D, 0x5A, 0x90, 0x00, 0x03, 0x00, 0x00, 0x00 });
            Assert.NotNull(ImageValidation.Validate(exe, Label));
        }

        [Fact]
        public void RejectsImageExtensionFakedByHeaderOnly()
        {
            // JPEG's first two bytes followed by garbage: passes a naive signature check but
            // is not a decodable image.
            var bytes = new byte[64];
            bytes[0] = 0xFF;
            bytes[1] = 0xD8;
            Assert.NotNull(ImageValidation.Validate(Convert.ToBase64String(bytes), Label));
        }

        [Fact]
        public void RejectsPayloadThatIsNotBase64()
        {
            var error = ImageValidation.Validate("ovo nije base64!!!", Label);
            Assert.NotNull(error);
            Assert.Contains("nije ispravno kodirana", error);
        }

        [Fact]
        public void RejectsAllowedLookingFormatThatIsNotOnTheList()
        {
            // BMP decodes fine, so it survives the magic-byte check and is only stopped by the
            // MIME allow-list - which is the point of having both checks.
            var error = ImageValidation.Validate(EncodedImage(16, 16, "bmp"), Label);
            Assert.NotNull(error);
            Assert.Contains("JPG, PNG ili WEBP", error);
        }

        [Fact]
        public void RejectsPictureOverTheSizeLimit()
        {
            // Just past the 5 MB ceiling; the check runs before decoding, so plain bytes suffice.
            var tooBig = Convert.ToBase64String(new byte[5 * 1024 * 1024 + 1]);
            var error = ImageValidation.Validate(tooBig, Label);
            Assert.NotNull(error);
            Assert.Contains("prevelika", error);
        }

        [Fact]
        public void ErrorMessageNamesTheFieldItRefersTo()
        {
            var error = ImageValidation.Validate("nije base64 %%%", "Slika obavijesti");
            Assert.StartsWith("Slika obavijesti", error);
        }
    }
}
