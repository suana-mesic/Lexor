using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ContractInsertValidator : AbstractValidator<ContractInsertRequest>
    {
        public ContractInsertValidator()
        {
            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("EmployeeId must be greater than 0");

            RuleFor(x => x.ContractTypeId)
                .GreaterThan(0).WithMessage("ContractTypeId must be greater than 0");

            RuleFor(x => x.StartDate)
                .NotEmpty().WithMessage("Start date is required");

            RuleFor(x => x.EndDate)
                .GreaterThan(x => x.StartDate).WithMessage("End date must be after start date")
                .When(x => x.EndDate.HasValue);

            RuleFor(x => x.BrutoSalary)
                .GreaterThan(0).WithMessage("Bruto salary must be greater than 0");

            RuleFor(x => x.WorkHoursPerDay)
                .GreaterThan(0).WithMessage("Work hours per day must be greater than 0")
                .LessThanOrEqualTo(24).WithMessage("Work hours per day cannot exceed 24");
        }
    }
}
