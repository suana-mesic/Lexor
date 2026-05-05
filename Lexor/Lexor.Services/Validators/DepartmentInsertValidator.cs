using FluentValidation;
using Lexor.Model.Requests;
using System.Data;

namespace Lexor.Services.Validators
{
    public class DepartmentInsertValidator : AbstractValidator<DepartmentInsertRequest>
    {
        public DepartmentInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");
        }
    }
}
