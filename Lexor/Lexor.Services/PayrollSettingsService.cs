using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Lexor.Services
{
    public class PayrollSettingsService : BaseCRUDService<PayrollSettings, PayrollSettingsResponse, PayrollSettingsSearchObject, PayrollSettingsInsertRequest, PayrollSettingsUpdateRequest>, IPayrollSettingsService
    {
        // The active settings are read on practically every payroll-related request (desktop
        // payroll screens, the mobile salary tab, every calculation) but change only when a new
        // rate set is entered — a few times a year. Cached here per guideline 8.2, invalidated
        // by every write below rather than by a short TTL, so a rate change is visible at once.
        private readonly IMemoryCache _cache;
        private const string CurrentSettingsCacheKey = "payroll-settings:current";

        public PayrollSettingsService(LexorDbContext dbContext, IMapper mapper, IValidator<PayrollSettingsInsertRequest> insertValidator, IValidator<PayrollSettingsUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor, IMemoryCache cache)
            : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
            _cache = cache;
        }

        private void InvalidateCurrentSettingsCache() => _cache.Remove(CurrentSettingsCacheKey);

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
                InvalidateCurrentSettingsCache();

                return await GetByIdAsync(entity.Id);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        // Editing or removing a settings record can change which one is active, so both writes
        // drop the cached copy.
        public override async Task<PayrollSettingsResponse> UpdateAsync(int id, PayrollSettingsUpdateRequest request)
        {
            var result = await base.UpdateAsync(id, request);
            InvalidateCurrentSettingsCache();
            return result;
        }

        public override async Task DeleteAsync(int id)
        {
            await base.DeleteAsync(id);
            InvalidateCurrentSettingsCache();
        }

        // Converts a work-days description into a bitmask (Mon=bit0 ... Sun=bit6).
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
            if (_cache.TryGetValue<PayrollSettingsResponse?>(CurrentSettingsCacheKey, out var cached))
                return cached;

            var now = DateTime.UtcNow;
            var current = await _dbContext.Set<PayrollSettings>()
                .Where(p => p.ValidFrom <= now && (p.ValidTo == null || p.ValidTo >= now))
                .OrderByDescending(p => p.ValidFrom)
                .FirstOrDefaultAsync();

            var response = current == null ? null : _mapper.Map<PayrollSettingsResponse>(current);

            // A short absolute expiry is a safety net for the one case writes cannot cover:
            // the active record ending simply because its ValidTo date has passed.
            _cache.Set(CurrentSettingsCacheKey, response, TimeSpan.FromMinutes(10));

            return response;
        }
    }
}
