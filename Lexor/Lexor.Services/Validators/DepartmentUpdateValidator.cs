using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class DepartmentUpdateValidator : AbstractValidator<DepartmentUpdateRequest>
    {
        public DepartmentUpdateValidator()
        {
            RuleFor(x => x.Name)
              .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");
        }
    }
}
