using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class PositionInsertValidator : AbstractValidator<PositionInsertRequest>
    {
        public PositionInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv pozicije je obavezan.")
                .MaximumLength(100).WithMessage("Naziv pozicije ne može imati više od 100 karaktera.");
        }
    }
}
