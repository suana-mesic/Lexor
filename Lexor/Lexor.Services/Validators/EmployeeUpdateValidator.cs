using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class EmployeeUpdateValidator : AbstractValidator<EmployeeUpdateRequest>
    {
        public EmployeeUpdateValidator()
        {
            RuleFor(x => x.User!)
                .SetValidator(new EmployeeUserUpdateValidator())
                .When(x => x.User != null);

            RuleFor(x => x.DateOfBirth)
                .LessThan(DateTime.UtcNow).WithMessage("Date of birth must be in the past")
                .When(x => x.DateOfBirth.HasValue);

            RuleFor(x => x.Address)
                .MaximumLength(200).WithMessage("Address cannot exceed 200 characters")
                .When(x => x.Address != null);

            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("CityId must be greater than 0")
                .When(x => x.CityId.HasValue);

            RuleFor(x => x.DepartmentId)
                .GreaterThan(0).WithMessage("DepartmentId must be greater than 0")
                .When(x => x.DepartmentId.HasValue);

            RuleFor(x => x.PositionId)
                .GreaterThan(0).WithMessage("PositionId must be greater than 0")
                .When(x => x.PositionId.HasValue);
        }
    }

    public class EmployeeUserUpdateValidator : AbstractValidator<EmployeeUserUpdateRequest>
    {
        public EmployeeUserUpdateValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name cannot be empty if provided")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters")
                .When(x => x.FirstName != null);

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name cannot be empty if provided")
                .MaximumLength(50).WithMessage("Last name cannot exceed 50 characters")
                .When(x => x.LastName != null);

            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Username cannot be empty if provided")
                .MaximumLength(100).WithMessage("Username cannot exceed 100 characters")
                .When(x => x.Username != null);

            RuleFor(x => x.Email)
                .EmailAddress().WithMessage("Email must be a valid email address")
                .MaximumLength(100).WithMessage("Email cannot exceed 100 characters")
                .When(x => !string.IsNullOrWhiteSpace(x.Email));

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Phone number cannot exceed 20 characters")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));
        }
    }

}
