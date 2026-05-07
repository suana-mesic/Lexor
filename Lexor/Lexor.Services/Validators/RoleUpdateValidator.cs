using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class RoleUpdateValidator : AbstractValidator<RoleUpdateRequest>
    {
        public RoleUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(50).WithMessage("Naziv uloge ne može imati više od 50 karaktera.");

            RuleFor(x => x.Description)
                .MaximumLength(200).WithMessage("Opis uloge ne može imati više od 200 karaktera.");
        }
    }
}
