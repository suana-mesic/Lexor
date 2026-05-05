using FluentValidation;
using Lexor.Model.Requests;
using System.Data;

namespace Lexor.Services.Validators
{
    public class RoleUpdateValidator : AbstractValidator<RoleUpdateRequest>
    {
        public RoleUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(50).WithMessage("Name cannot exceed 50 characters.");
            RuleFor(x => x.Description)
                .MaximumLength(200).WithMessage("Description cannot exceed 200 characters.");
        }
    }
}
