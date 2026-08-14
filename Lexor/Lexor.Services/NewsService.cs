using FluentValidation;
using Lexor.Model.Constants;
using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services
{
    public class NewsService : BaseCRUDService<News, NewsResponse, NewsSearchObject, NewsInsertRequest, NewsUpdateRequest>, INewsService
    {
        public NewsService(LexorDbContext dbContext, IMapper mapper, IValidator<NewsInsertRequest> insertValidator, IValidator<NewsUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
        }

        protected override IQueryable<News> ApplyFilters(IQueryable<News> query, NewsSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.Title))
                query = query.Where(n => n.Title.ToLower().Contains(search.Title.ToLower()));

            return query;
        }

        // Stamp the current user as the author so ownership checks (below) have something to compare.
        protected override News MapInsertRequestToEntity(NewsInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            entity.PublishedByUserId = _userAccessor.GetUserId();
            return entity;
        }

        public override async Task<NewsResponse> UpdateAsync(int id, NewsUpdateRequest request)
        {
            await EnsureCanModifyAsync(id);
            return await base.UpdateAsync(id, request);
        }

        public override async Task DeleteAsync(int id)
        {
            await EnsureCanModifyAsync(id);
            await base.DeleteAsync(id);
        }

        // A user may edit/delete only their own announcements; an administrator may edit/delete any.
        // A null author (legacy/seeded rows) is therefore administrator-only.
        private async Task EnsureCanModifyAsync(int id)
        {
            if (_userAccessor.IsInRole(RoleNames.Administrator))
                return;

            var row = await _dbContext.Set<News>()
                .Where(n => n.Id == id)
                .Select(n => new { n.PublishedByUserId })
                .FirstOrDefaultAsync();
            if (row == null)
                return; // let the base operation report a proper "not found"

            if (row.PublishedByUserId == null || row.PublishedByUserId != _userAccessor.GetUserId())
                throw new BusinessException("Možete uređivati i brisati samo vlastite obavijesti.");
        }
    }
}
