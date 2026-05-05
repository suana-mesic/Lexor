using FluentValidation;
using Lexor.Model.Requests;
using System.Data;

namespace Lexor.Services.Validators
{
    public class RoleInsertValidator : AbstractValidator<RoleInsertRequest>
    {
        public RoleInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(50).WithMessage("Name cannot exceed 50 characters.");
            RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Description is required")
                .MaximumLength(200).WithMessage("Description cannot exceed 200 characters.");
        }
    }
}
