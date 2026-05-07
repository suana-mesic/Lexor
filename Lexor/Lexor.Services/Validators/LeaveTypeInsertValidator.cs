using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LeaveTypeInsertValidator : AbstractValidator<LeaveTypeInsertRequest>
    {
        public LeaveTypeInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv tipa odsustva je obavezan.")
                .MaximumLength(100).WithMessage("Naziv tipa odsustva ne može imati više od 100 karaktera.");
        }
    }
}
