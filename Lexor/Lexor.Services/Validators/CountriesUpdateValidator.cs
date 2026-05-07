using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class CountriesUpdateValidator : AbstractValidator<CountryUpdateRequest>
    {
        public CountriesUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(100).WithMessage("Naziv države ne može imati više od 100 karaktera.");
        }
    }
}
