using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class CityInsertValidator : AbstractValidator<CityInsertRequest>
    {
        public CityInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv grada je obavezan.")
                .MaximumLength(100).WithMessage("Naziv grada ne može imati više od 100 karaktera.");

            RuleFor(x => x.CountryId)
                .GreaterThan(0).WithMessage("CountryId mora biti veći od 0.");
        }
    }
}
