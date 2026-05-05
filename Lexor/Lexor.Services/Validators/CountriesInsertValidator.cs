using FluentValidation;
using Lexor.Model.Requests;
using System.Data;

namespace Lexor.Services.Validators
{
    public class CountriesInsertValidator : AbstractValidator<CountryInsertRequest>
    {
        public CountriesInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(100);
        }
    }
}
