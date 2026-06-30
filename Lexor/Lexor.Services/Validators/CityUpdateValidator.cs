using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class CityUpdateValidator : AbstractValidator<CityUpdateRequest>
    {
        public CityUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(100).WithMessage("Naziv grada ne može imati više od 100 karaktera.");

            RuleFor(x => x.CountryId)
                .GreaterThan(0).WithMessage("Država je obavezna.")
                .When(x => x.CountryId.HasValue);
        }
    }
}
