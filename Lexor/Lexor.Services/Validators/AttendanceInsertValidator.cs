using FluentValidation;
using Lexor.Model.Requests;

namespace Lexor.Services.Validators
{
    public class AttendanceInsertValidator:AbstractValidator<AttendanceInsertRequest>
    {
        public AttendanceInsertValidator()
        {
            RuleFor(x => x.EmployeeId)
                .GreaterThan(0).WithMessage("Uposlenik je obavezan.");

            RuleFor(x => x.RfidCardId)
              .GreaterThan(0).WithMessage("RFID kartica je obavezna.");

        }
    }
}
