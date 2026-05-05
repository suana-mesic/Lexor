using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class LegalDocumentCategoryUpdateValidator : AbstractValidator<LegalDocumentCategoryUpdateRequest>
    {
        public LegalDocumentCategoryUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(150).WithMessage("Name cannot exceed 150 characters.");
        }
    }
}
