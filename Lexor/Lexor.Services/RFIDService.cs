using Lexor.Model.Exceptions;
using FluentValidation;
using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{

    public class RFIDService : BaseCRUDService<RfidCard, RFIDResponse, RFIDSearchObject, RFIDInsertRequest, RFIDUpdateRequest>, IRFIDService
    {
        public RFIDService(LexorDbContext dbContext, IMapper mapper, IValidator<RFIDInsertRequest> insertValidator, IValidator<RFIDUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor) : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {

        }

        public override async Task<RFIDResponse> InsertAsync(RFIDInsertRequest request)
        {
            var duplicate = await _dbContext.Set<RfidCard>()
                .AnyAsync(c => c.Uid == request.Uid && c.IsActive);

            if (duplicate)
                throw new ValidationException("Već postoji aktivna kartica sa ovim UID-om.");

            // An employee may have at most one active card at a time.
            if (request.IsActive)
            {
                var activeCard = await _dbContext.Set<RfidCard>()
                    .Include(c => c.Employee)
                        .ThenInclude(e => e.User)
                    .FirstOrDefaultAsync(c => c.EmployeeId == request.EmployeeId && c.IsActive);

                if (activeCard != null)
                {
                    var name = $"{activeCard.Employee.User.FirstName} {activeCard.Employee.User.LastName}";
                    throw new ValidationException(
                        $"Uposlenik {name} već ima aktivnu karticu. " +
                        "Potrebno je prvo deaktivirati staru karticu kako bi se nova mogla dodati.");
                }
            }

            return await base.InsertAsync(request);
        }

        public async Task<RFIDResponse> DeactivateAsync(int id)
        {
            var card = await _dbContext.Set<RfidCard>().FindAsync(id)
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(RfidCard), id));

            if (!card.IsActive)
                return await GetByIdAsync(id);

            card.IsActive = false;
            card.DeactivatedAt = DateTime.UtcNow;

            await _dbContext.SaveChangesAsync();
            return await GetByIdAsync(id);
        }

        protected override IQueryable<RfidCard> ApplyFilters(IQueryable<RfidCard> query, RFIDSearchObject? search)
        {
            if (search != null)
            {
                if (search.EmployeeId.HasValue)
                {
                    query = query.Where(rfid => rfid.EmployeeId == search.EmployeeId);
                }

                if (!string.IsNullOrWhiteSpace(search.EmployeeName))
                {
                    var term = search.EmployeeName.ToLower();
                    query = query.Where(rfid =>
                        (rfid.Employee.User.FirstName + " " + rfid.Employee.User.LastName)
                            .ToLower().Contains(term));
                }

                query = search.ActivityStatus switch
                {
                    ActivityStatus.Active => query.Where(rfid => rfid.IsActive),
                    ActivityStatus.Inactive => query.Where(rfid => !rfid.IsActive),
                    ActivityStatus.All => query,
                    null => query,
                    _ => throw new ValidationException("Nevažeći filter statusa aktivnosti.")
                };
            }
            return query;
        }

        protected override IQueryable<RfidCard> IncludeRelatedEntities(RFIDSearchObject? search, IQueryable<RfidCard> query)
        {
            return query
                .Include(rfid => rfid.Employee)
                    .ThenInclude(e => e.User);
        }
    }
}
