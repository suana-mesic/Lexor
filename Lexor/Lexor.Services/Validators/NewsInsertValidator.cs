using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Services.Helpers;

namespace Lexor.Services.Validators
{
    public class NewsInsertValidator : AbstractValidator<NewsInsertRequest>
    {
        public NewsInsertValidator()
        {
            RuleFor(x => x.Title)
                .NotEmpty().WithMessage("Naslov je obavezan.")
                .MaximumLength(200).WithMessage("Naslov može imati najviše 200 znakova.");

            RuleFor(x => x.Content)
                .NotEmpty().WithMessage("Sadržaj je obavezan.")
                .MaximumLength(4000).WithMessage("Sadržaj može imati najviše 4000 znakova.");

            RuleFor(x => x.ImageBase64).ValidImage("Slika obavijesti");
        }
    }
}
