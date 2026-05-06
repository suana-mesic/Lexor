using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class EmployeeInsertValidator : AbstractValidator<EmployeeInsertRequest>
    {
        public EmployeeInsertValidator()
        {
            RuleFor(x => x.User)
                .NotNull().WithMessage("User data is required")
                .SetValidator(new EmployeeUserInsertValidator());

            RuleFor(x => x.DateOfBirth)
                .NotEmpty().WithMessage("Date of birth is required")
                .LessThan(DateTime.UtcNow).WithMessage("Date of birth must be in the past");

            RuleFor(x => x.Address)
                .NotEmpty().WithMessage("Address is required")
                .MaximumLength(200).WithMessage("Address cannot exceed 200 characters");

            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("CityId must be greater than 0");

            RuleFor(x => x.DepartmentId)
                .GreaterThan(0).WithMessage("DepartmentId must be greater than 0");

            RuleFor(x => x.PositionId)
                .GreaterThan(0).WithMessage("PositionId must be greater than 0");

            RuleFor(x => x.HireDate)
                .NotEmpty().WithMessage("Hire date is required");
        }
    }

    public class EmployeeUserInsertValidator : AbstractValidator<EmployeeUserInsertRequest>
    {
        public EmployeeUserInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name is required")
                .MaximumLength(50).WithMessage("Last name cannot exceed 50 characters");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required")
                .EmailAddress().WithMessage("Email must be a valid email address")
                .MaximumLength(100).WithMessage("Email cannot exceed 100 characters");

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Phone number cannot exceed 20 characters")
                .When(x => !string.IsNullOrWhiteSpace(x.PhoneNumber));
        }
    }

}
