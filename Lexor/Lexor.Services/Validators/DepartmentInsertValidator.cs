using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class DepartmentInsertValidator : AbstractValidator<DepartmentInsertRequest>
    {
        public DepartmentInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv odjela je obavezan.")
                .MaximumLength(100).WithMessage("Naziv odjela ne može imati više od 100 karaktera.");
        }
    }
}
