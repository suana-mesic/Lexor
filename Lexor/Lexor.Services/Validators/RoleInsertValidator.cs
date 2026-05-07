using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class RoleInsertValidator : AbstractValidator<RoleInsertRequest>
    {
        public RoleInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv uloge je obavezan.")
                .MaximumLength(50).WithMessage("Naziv uloge ne može imati više od 50 karaktera.");

            RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Opis uloge je obavezan.")
                .MaximumLength(200).WithMessage("Opis uloge ne može imati više od 200 karaktera.");
        }
    }
}
