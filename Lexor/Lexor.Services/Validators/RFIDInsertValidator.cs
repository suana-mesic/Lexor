using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class RFIDInsertValidator : AbstractValidator<RFIDInsertRequest>
    {
        public RFIDInsertValidator()
        {
            RuleFor(x => x.Uid)
                .NotNull().WithMessage("Uid je obavezan.")
                .MaximumLength(50).WithMessage("Uid ne može imati više od 50 karaktera.");

            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("EmployeeId mora biti veći od 0.");
        }
    }
}
