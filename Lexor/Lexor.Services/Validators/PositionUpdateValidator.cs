using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class PositionUpdateValidator : AbstractValidator<PositionUpdateRequest>
    {
        public PositionUpdateValidator()
        {
            RuleFor(x => x.Name)
              .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");
        }
    }
}
