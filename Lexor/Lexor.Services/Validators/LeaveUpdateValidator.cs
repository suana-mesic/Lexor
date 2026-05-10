using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LeaveUpdateValidator : AbstractValidator<LeaveUpdateRequest>
    {
        public LeaveUpdateValidator()
        {
            RuleFor(x => x.LeaveTypeId)
                .GreaterThan(0).WithMessage("ID razloga odsustva mora biti veći od 0.")
                .When(x => x.LeaveTypeId.HasValue);

            RuleFor(x => x.Reason)
                .NotEmpty().WithMessage("Razlog odsustva ne može biti prazan.")
                .MaximumLength(1000).WithMessage("Razlog odsustva ne može imati više od 1000 karaktera.")
                .When(x => x.Reason != null);

            RuleFor(x => x.DateFrom!.Value)
                .GreaterThanOrEqualTo(_ => DateOnly.FromDateTime(DateTime.UtcNow))
                .WithMessage("Datum početka odsustva mora biti danas ili u budućnosti.")
                .When(x => x.DateFrom.HasValue);

            RuleFor(x => x)
                .Must(x => x.DateTo!.Value >= x.DateFrom!.Value)
                .WithMessage("Datum završetka odsustva mora biti nakon datuma početka.")
                .When(x => x.DateFrom.HasValue && x.DateTo.HasValue);
        }
    }
}
