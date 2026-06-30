using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LegalDocumentInsertValidator : AbstractValidator<LegalDocumentInsertRequest>
    {
        private const int MaxFileSizeMb = 10;
        private const long MaxFileSizeBytes = MaxFileSizeMb * 1024L * 1024L;

        public LegalDocumentInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv dokumenta je obavezan.")
                .MaximumLength(200).WithMessage("Naziv dokumenta ne može imati više od 200 karaktera.");

            RuleFor(x => x.CategoryId)
                .GreaterThan(0).WithMessage("Kategorija je obavezna.");

            RuleFor(x => x.FileBase64)
                .NotEmpty().WithMessage("Dokument (fajl) je obavezan.")
                .Must(BeValidBase64).WithMessage("Sadržaj fajla nije ispravan.")
                .Must(BePdf).WithMessage("Dokument mora biti PDF fajl.");

            RuleFor(x => x.FileSize)
                .GreaterThan(0).WithMessage("Fajl je prazan.")
                .LessThanOrEqualTo(MaxFileSizeBytes)
                .WithMessage($"Dokument ne može biti veći od {MaxFileSizeMb} MB.");
        }

        private static bool BeValidBase64(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return false;
            var buffer = new byte[value.Length];
            return Convert.TryFromBase64String(value, buffer, out _);
        }

        // PDF files start with the "%PDF" signature (0x25 0x50 0x44 0x46).
        // Decode only the header (first 8 base64 chars = 6 bytes) to avoid decoding the whole file.
        private static bool BePdf(string value)
        {
            if (string.IsNullOrWhiteSpace(value) || value.Length < 8) return false;
            try
            {
                var head = Convert.FromBase64String(value.Substring(0, 8));
                return head.Length >= 4
                    && head[0] == 0x25 && head[1] == 0x50
                    && head[2] == 0x44 && head[3] == 0x46;
            }
            catch
            {
                return false;
            }
        }
    }
}
