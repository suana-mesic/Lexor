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

        public async Task<RFIDResponse> DeactivateAsync(int id)
        {
            var card = await _dbContext.Set<RfidCard>().FindAsync(id)
                ?? throw new KeyNotFoundException(EntityDisplayMessage.NotFound(typeof(RfidCard), id));

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

                query = search.ActivityStatus switch
                {
                    ActivityStatus.Active => query.Where(rfid => rfid.IsActive),
                    ActivityStatus.Inactive => query.Where(rfid => !rfid.IsActive),
                    ActivityStatus.All => query,
                    null => query,
                    _ => throw new ValidationException(
                        $"Nevažeća vrijednost ActivityStatus: {(int)search.ActivityStatus.Value}.")
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
