using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class CountriesInsertValidator : AbstractValidator<CountryInsertRequest>
    {
        public CountriesInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv države je obavezan.")
                .MaximumLength(100).WithMessage("Naziv države ne može imati više od 100 karaktera.");
        }
    }
}
