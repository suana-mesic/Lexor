using FluentValidation;
using Lexor.Model.Requests;
using System.Data;

namespace Lexor.Services.Validators
{
    public class CityInsertValidator : AbstractValidator<CityInsertRequest>
    {
        public CityInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");
            RuleFor(x => x.CountryId)
                .GreaterThan(0)
                .WithMessage("CountryId must be greather than 0");
        }
    }
}
