using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class ContractInsertValidator : AbstractValidator<ContractInsertRequest>
    {
        public ContractInsertValidator()
        {
            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("EmployeeId mora biti veći od 0.");

            RuleFor(x => x.ContractTypeId)
                .GreaterThan(0).WithMessage("ContractTypeId mora biti veći od 0.");

            RuleFor(x => x.StartDate)
                .NotEmpty().WithMessage("Datum početka je obavezan.");

            RuleFor(x => x.EndDate)
                .GreaterThan(x => x.StartDate).WithMessage("Datum završetka mora biti nakon datuma početka.")
                .When(x => x.EndDate.HasValue);

            RuleFor(x => x.BrutoSalary)
                .GreaterThan(0).WithMessage("Bruto plata mora biti veća od 0.");

            RuleFor(x => x.WorkHoursPerDay)
                .GreaterThan(0).WithMessage("Broj radnih sati po danu mora biti veći od 0.")
                .LessThanOrEqualTo(24).WithMessage("Broj radnih sati po danu ne može biti veći od 24.");
        }
    }
}
