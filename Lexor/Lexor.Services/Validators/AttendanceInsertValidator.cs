using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class AttendanceInsertValidator:AbstractValidator<AttendanceInsertRequest>
    {
        public AttendanceInsertValidator()
        {
            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("ID uposlenika mora biti veći od 0.");

            RuleFor(x => x.RfidCardId)
              .GreaterThan(0).WithMessage("ID RFID kartice mora biti veći od 0.");

        }
    }
}
