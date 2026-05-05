using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class CityUpdateValidator:AbstractValidator<CityUpdateRequest>
    {
        public CityUpdateValidator()
        {
            RuleFor(x => x.Name)
              .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");
            RuleFor(x => x.CountryId)
                .GreaterThan(0)
                .WithMessage("CountryId must be greather than 0")
                .When(x => x.CountryId.HasValue);
        }
    }
}
