using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LeaveInsertValidator : AbstractValidator<LeaveInsertRequest>
    {
        public LeaveInsertValidator()
        {
            RuleFor(x => x.LeaveTypeId)
                .GreaterThan(0).WithMessage("Tip odsustva je obavezan.");

            RuleFor(x => x.Reason)
                .NotEmpty().WithMessage("Razlog odsustva je obavezan.")
                .MaximumLength(1000).WithMessage("Razlog odsustva ne može imati više od 1000 karaktera.");

            RuleFor(x => x.DateFrom)
                .GreaterThanOrEqualTo(_ => DateOnly.FromDateTime(DateTime.UtcNow))
                .WithMessage("Datum početka odsustva mora biti danas ili u budućnosti.");

            RuleFor(x => x)
                .Must(x => x.DateTo >= x.DateFrom)
                .WithMessage("Datum završetka odsustva mora biti nakon datuma početka.");
        }
    }
}
