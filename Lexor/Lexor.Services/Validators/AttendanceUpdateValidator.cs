using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class AttendanceUpdateValidator : AbstractValidator<AttendanceUpdateRequest>
    {
        public AttendanceUpdateValidator()
        {
            RuleFor(x => x.CorrectionReason)
                .NotEmpty().WithMessage("Razlog korekcije prisustva je obavezan.")
                .MaximumLength(500).WithMessage("Razlog korekcije prisustva ne može imati više od 500 karaktera.");

            RuleFor(x => x)
                .Must(x => x.DateTimeEntered.HasValue || x.DateTimeLeft.HasValue)
                .WithMessage("Mora biti naveden barem jedan od: vrijeme ulaska ili vrijeme izlaska.");

            RuleFor(x => x)
                .Must(x => !x.DateTimeEntered.HasValue || !x.DateTimeLeft.HasValue || x.DateTimeLeft > x.DateTimeEntered)
                .WithMessage("Vrijeme izlaska mora biti nakon vremena ulaska.");
        }
    }
}
