using FluentValidation;
using FluentValidation.Results;
using Lexor.Model.Constants;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class AttendanceService : BaseCRUDService<Attendance, AttendanceResponse, AttendanceSearchObject, AttendanceInsertRequest, AttendanceUpdateRequest>, IAttendanceService
    {
        public AttendanceService(LexorDbContext dbContext, IMapper mapper, IValidator<AttendanceInsertRequest> insertValidator, IValidator<AttendanceUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
        }
        protected override IQueryable<Attendance> ApplyFilters(IQueryable<Attendance> query, AttendanceSearchObject? search)
        {
            if (search?.DepartmentId.HasValue == true)
            {
                query = query.Where(a => a.Employee.DepartmentId == search.DepartmentId);
            }
            if (search?.FromDate.HasValue == true && search?.ToDate.HasValue == true)
            {
                query = query.Where(a => a.Date >= search.FromDate && a.Date <= search.ToDate);
            }
            if (_userAccessor.IsInRole(RoleNames.Administrator))
            {
                // admin may optionally filter by any employee
                if (search?.EmployeeId.HasValue == true)
                    query = query.Where(a => a.EmployeeId == search.EmployeeId);
            }
            else
            {
                var currentUserId = _userAccessor.GetUserId()
                    ?? throw new UnauthorizedAccessException("Korisnik nije autentificiran.");
                query = query.Where(a => a.Employee.UserId == currentUserId);
            }
            return query;
        }

        public async Task<ScanResponse> ScanAsync(ScanRequest request)
        {
            // find card in database
            var card = await _dbContext.Set<RfidCard>()
                .Include(c => c.Employee)
                    .ThenInclude(e => e.User)
                .FirstOrDefaultAsync(c => c.Uid == request.Uid);

            // validate card
            if (card == null)
            {
                return new ScanResponse
                {
                    Status = "REJECTED",
                    LedColor = "RED",
                    Buzzer = true,
                    Message = "Kartica nije registrovana"
                };
            }

            if (!card.IsActive)
                return new ScanResponse
                {
                    Status = "REJECTED",
                    LedColor = "RED",
                    Buzzer = true,
                    Message = "Kartica je deaktivirana."
                };

            if (!card.Employee.IsActive)
            {
                return new ScanResponse
                {
                    Status = "REJECTED",
                    LedColor = "RED",
                    Buzzer = true,
                    Message = "Zaposlenik nije aktivan."
                };
            }

            // find current attendance record
            var now = DateTime.UtcNow;
            var today = DateOnly.FromDateTime(now);

            var attendance = await _dbContext.Set<Attendance>()
                .FirstOrDefaultAsync(a => a.EmployeeId == card.EmployeeId && a.Date == today);

            string status;
            string ledColor;

            if (attendance == null)
            {
                // entering -> create new record
                attendance = new Attendance
                {
                    EmployeeId = card.EmployeeId,
                    RfidCardId = card.Id,
                    Date = today,
                    DateTimeEntered = now
                };
                _dbContext.Set<Attendance>().Add(attendance);
                status = "ENTERED";
                ledColor = "GREEN";
            }
            else
            {
                attendance.DateTimeLeft = now;
                status = "LEFT";
                ledColor = "BLUE";
            }
            await _dbContext.SaveChangesAsync();

            var time = (status == "ENTERED" ? attendance.DateTimeEntered : attendance.DateTimeLeft)?.ToString("HH:mm");

            return new ScanResponse
            {
                Status = status,
                LedColor = ledColor,
                Buzzer = true,
                Message = $"{card.Employee.User.FirstName} {card.Employee.User.LastName} - {(status == "ENTERED" ? "ulazak" : "izlazak")} u {time}.",
                EmployeeId = card.EmployeeId,
                EmployeeFullName = $"{card.Employee.User.FirstName} {card.Employee.User.LastName}",
                DateTimeEntered = attendance.DateTimeEntered,
                DateTimeLeft = attendance.DateTimeLeft
            };
        }
        public override async Task<AttendanceResponse> GetByIdAsync(int id)
        {
            var response = await base.GetByIdAsync(id);

            if (!_userAccessor.IsInRole(RoleNames.Administrator))
            {
                var currentUserId = _userAccessor.GetUserId();
                var ownerUserId = await _dbContext.Set<Attendance>()
                    .Where(a => a.Id == id)
                    .Select(a => (int?)a.Employee.UserId)
                    .FirstOrDefaultAsync();
                if (currentUserId != ownerUserId)
                    throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Attendance), id));
            }
            return response;
        }

        public override async Task<AttendanceResponse> UpdateAsync(int id, AttendanceUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new ValidationException(errors);
            }

            var entity = await _dbContext.Set<Attendance>().FindAsync(id) ??
                throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(Attendance), id));

            _mapper.Map(request, entity);

            entity.IsCorrected = true;
            entity.CorrectionReason = request.CorrectionReason;

            ApplyUpdateAuditFields(entity);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }

        protected override IQueryable<Attendance> IncludeRelatedEntities(AttendanceSearchObject? search, IQueryable<Attendance> query)
        {
            if (_userAccessor.IsInRole(RoleNames.Administrator))
            {
                return query
                    .Include(a => a.Employee)
                    .Include(a => a.Employee.User)
                    .Include(a => a.Employee.Department);
            }
            return query;
        }
    }
}
