using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class RFIDInsertValidator : AbstractValidator<RFIDInsertRequest>
    {
        public RFIDInsertValidator()
        {
            RuleFor(x => x.Uid)
                .NotEmpty().WithMessage("UID je obavezan.")
                .MaximumLength(50).WithMessage("UID ne može imati više od 50 karaktera.")
                .Matches("^[0-9A-Fa-f]+$")
                .WithMessage("UID kartice može sadržavati samo cifre i slova A-F.");

            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("Uposlenik je obavezan.");
        }
    }
}
