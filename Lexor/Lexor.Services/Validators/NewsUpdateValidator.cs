using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Services.Helpers;

namespace Lexor.Services.Validators
{
    public class NewsUpdateValidator : AbstractValidator<NewsUpdateRequest>
    {
        public NewsUpdateValidator()
        {
            // Only validate fields that are actually provided (partial update).
            When(x => x.Title != null, () =>
            {
                RuleFor(x => x.Title)
                    .NotEmpty().WithMessage("Naslov ne može biti prazan.")
                    .MaximumLength(200).WithMessage("Naslov može imati najviše 200 znakova.");
            });

            When(x => x.Content != null, () =>
            {
                RuleFor(x => x.Content)
                    .NotEmpty().WithMessage("Sadržaj ne može biti prazan.")
                    .MaximumLength(4000).WithMessage("Sadržaj može imati najviše 4000 znakova.");
            });

            RuleFor(x => x.ImageBase64).ValidImage("Slika obavijesti");
        }
    }
}
