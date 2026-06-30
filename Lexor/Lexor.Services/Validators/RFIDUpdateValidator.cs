using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class RFIDUpdateValidator : AbstractValidator<RFIDUpdateRequest>
    {
        public RFIDUpdateValidator()
        {
            RuleFor(x => x.Uid)
                .NotEmpty().WithMessage("UID je obavezan.")
                .MaximumLength(50).WithMessage("UID ne može imati više od 50 karaktera.")
                .Matches("^[0-9A-Fa-f:]+$")
                .WithMessage("UID kartice može sadržavati samo cifre, slova A-F i dvotačke.")
                .When(x => x.Uid != null);

            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("Uposlenik je obavezan.")
                .When(x => x.EmployeeId.HasValue);
        }
    }
}
