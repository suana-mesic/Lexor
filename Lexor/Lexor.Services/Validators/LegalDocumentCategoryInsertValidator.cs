using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LegalDocumentCategoryInsertValidator : AbstractValidator<LegalDocumentCategoryInsertRequest>
    {
        public LegalDocumentCategoryInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Name is required")
                .MaximumLength(150).WithMessage("Name cannot exceed 150 characters.");
        }
    }
}
