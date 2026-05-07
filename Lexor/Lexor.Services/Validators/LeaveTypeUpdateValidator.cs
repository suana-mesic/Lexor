using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LeaveTypeUpdateValidator : AbstractValidator<LeaveTypeUpdateRequest>
    {
        public LeaveTypeUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(100).WithMessage("Naziv tipa odsustva ne može imati više od 100 karaktera.");
        }
    }
}
