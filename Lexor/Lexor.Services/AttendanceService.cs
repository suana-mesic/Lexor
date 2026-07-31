using Lexor.Model.Exceptions;
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
using System.Runtime.CompilerServices;

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
            if (search?.FromDate.HasValue == true)
            {
                query = query.Where(a => a.Date >= search.FromDate);
            }
            if (search?.ToDate.HasValue == true)
            {
                query = query.Where(a => a.Date <= search.ToDate);
            }
            if (_userAccessor.IsBackOffice())
            {
                // admin may optionally filter by any employee
                if (search?.EmployeeId.HasValue == true)
                    query = query.Where(a => a.EmployeeId == search.EmployeeId);

                if (!string.IsNullOrWhiteSpace(search?.EmployeeName))
                {
                    var term = search.EmployeeName.ToLower();
                    query = query.Where(a =>
                        (a.Employee.User.FirstName + " " + a.Employee.User.LastName)
                            .ToLower().Contains(term));
                }
            }
            else
            {
                var currentUserId = _userAccessor.GetUserId();
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

            if (!_userAccessor.IsBackOffice())
            {
                var currentUserId = _userAccessor.GetUserId();
                var ownerUserId = await _dbContext.Set<Attendance>()
                    .Where(a => a.Id == id)
                    .Select(a => (int?)a.Employee.UserId)
                    .FirstOrDefaultAsync();
                if (currentUserId != ownerUserId)
                    throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Attendance), id));
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

            await EnsureNotOwnAttendance(id);

            var entity = await _dbContext.Set<Attendance>().FindAsync(id) ??
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Attendance), id));

            _mapper.Map(request, entity);

            entity.IsCorrected = true;
            entity.CorrectionReason = request.CorrectionReason;

            // WorkedHours is recomputed centrally in LexorDbContext.SaveChanges — no manual set here.

            ApplyUpdateAuditFields(entity);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }

        public override async Task DeleteAsync(int id)
        {
            await EnsureNotOwnAttendance(id);
            await base.DeleteAsync(id);
        }

        // An administrator must not edit or delete their own attendance record.
        private async Task EnsureNotOwnAttendance(int id)
        {
            var currentUserId = _userAccessor.GetUserId();
            var ownerUserId = await _dbContext.Set<Attendance>()
                .Where(a => a.Id == id)
                .Select(a => (int?)a.Employee.UserId)
                .FirstOrDefaultAsync();

            if (ownerUserId != null && ownerUserId == currentUserId)
                throw new BusinessException("Ne možete uređivati niti brisati vlastito prisustvo.");
        }

        protected override IQueryable<Attendance> IncludeRelatedEntities(AttendanceSearchObject? search, IQueryable<Attendance> query)
        {
            if (_userAccessor.IsBackOffice())
            {
                return query
                    .Include(a => a.Employee)
                    .Include(a => a.Employee.User)
                    .Include(a => a.Employee.Department);
            }
            return query;
        }

        public async Task<AttendanceSummaryResponse> GetAttendanceSummaryAsync()
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var thisMonth = today.Month;
            var thisYear = today.Year;
            var todaysStatus = "";

            var currentUserId = _userAccessor.GetUserId();

            var todaysAttendance = await _dbContext.Attendances
                .Where(x => x.Employee.UserId == currentUserId && x.Date == today)
                .Select(x => new { x.DateTimeEntered, x.WorkedHours })
                .FirstOrDefaultAsync();

            // Active payroll settings (used for work-start time and the working-day mask).
            var settings = await _dbContext.PayrollSettings
                .OrderByDescending(x => x.ValidFrom)
                .FirstAsync();

            if (todaysAttendance == null)
            {
                todaysStatus = "Niste prisutni";
            }
            else if (todaysAttendance.DateTimeEntered.HasValue)
            {
                var enteredTime = TimeOnly.FromDateTime(todaysAttendance.DateTimeEntered.Value.ToLocalTime());
                if (enteredTime < settings.WorkStartTime)
                    todaysStatus = "Došli ste ranije";
                else if (enteredTime > settings.WorkStartTime)
                    todaysStatus = "Došli ste kasnije";
                else
                    todaysStatus = "Došli ste tačno na vrijeme";
            }

            var thisMonthsAttendance = await _dbContext.Attendances
                .Where(x => x.Employee.UserId == currentUserId &&
                            x.Date.Month == thisMonth &&
                            x.Date.Year == thisYear)
                .Select(x => new { x.WorkedHours })
                .ToListAsync();

            var monthTotalHours = thisMonthsAttendance.Sum(x => x.WorkedHours ?? 0);

            var totalWorkDays = Enumerable.Range(1, today.Day)
                .Select(d => new DateOnly(thisYear, thisMonth, d))
                .Count(d => settings.IsWorkDay(d.DayOfWeek));

            var attendanceRate = totalWorkDays > 0
                ? (double)thisMonthsAttendance.Count / totalWorkDays * 100
                : 0;

            return new AttendanceSummaryResponse
            {
                TodayWorkedHours = todaysAttendance?.WorkedHours ?? 0,
                MonthTotalHours = monthTotalHours,
                MonthAttendanceRate = Math.Round(attendanceRate, 1),
                TodayStatus = todaysStatus
            };
        }
    }
}
