using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class PayrollSettingsService : BaseCRUDService<PayrollSettings, PayrollSettingsResponse, PayrollSettingsSearchObject, PayrollSettingsInsertRequest, PayrollSettingsUpdateRequest>, IPayrollSettingsService
    {
        public PayrollSettingsService(LexorDbContext dbContext, IMapper mapper, IValidator<PayrollSettingsInsertRequest> insertValidator, IValidator<PayrollSettingsUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
        }

        protected override IQueryable<PayrollSettings> ApplyFilters(IQueryable<PayrollSettings> query, PayrollSettingsSearchObject? search)
        {
            return query.OrderByDescending(p => p.ValidFrom);
        }

        public override async Task<PayrollSettingsResponse> InsertAsync(PayrollSettingsInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            await using var tx = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                var activeSettings = await _dbContext.Set<PayrollSettings>()
                    .Where(p => p.ValidTo == null)
                    .ToListAsync();

                foreach (var setting in activeSettings)
                {
                    setting.ValidTo = request.ValidFrom.AddDays(-1);
                }

                var entity = _mapper.Map<PayrollSettings>(request);
                entity.WorkDaysMask = DescriptionToMask(request.WorkDaysDescription);
                _dbContext.Set<PayrollSettings>().Add(entity);
                await _dbContext.SaveChangesAsync();

                await tx.CommitAsync();

                return await GetByIdAsync(entity.Id);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        // Pretvara opis radnih dana u bitmask (Pon=bit0 ... Ned=bit6).
        public static int DescriptionToMask(string? description) => description?.Trim() switch
        {
            "Pon-Sub" => 63,
            "Pon-Ned" => 127,
            _ => 31, // Mon-Fri (default)
        };

        // Converts the bitmask back into a human-readable description (for the response).
        public static string MaskToDescription(int mask) => mask switch
        {
            63 => "Pon-Sub",
            127 => "Pon-Ned",
            _ => "Pon-Pet",
        };

        public async Task<PayrollSettingsResponse?> GetCurrentAsync()
        {
            var now = DateTime.UtcNow;
            var current = await _dbContext.Set<PayrollSettings>()
                .Where(p => p.ValidFrom <= now && (p.ValidTo == null || p.ValidTo >= now))
                .OrderByDescending(p => p.ValidFrom)
                .FirstOrDefaultAsync();

            return current == null ? null : _mapper.Map<PayrollSettingsResponse>(current);
        }
    }
}
