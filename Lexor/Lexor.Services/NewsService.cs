using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using MapsterMapper;

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
    }
}
