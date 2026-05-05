using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LeaveTypeInsertValidator : AbstractValidator<LeaveTypeInsertRequest>
    {
        public LeaveTypeInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(100).WithMessage("Name cannot exceed 100 characters.");
        }
    }
}
