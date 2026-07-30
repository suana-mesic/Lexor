using EasyNetQ;
using FluentValidation;
using Lexor.Model;
using Lexor.Model.Exceptions;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System.Linq.Dynamic.Core;

namespace Lexor.Services
{
    public class LegalDocumentService : BaseCRUDService<LegalDocument, LegalDocumentResponse, LegalDocumentSearchObject, LegalDocumentInsertRequest, LegalDocumentUpdateRequest>, ILegalDocumentService
    {
        private readonly IBus _bus;
        public LegalDocumentService(LexorDbContext dbContext, IMapper mapper, IValidator<LegalDocumentInsertRequest> insertValidator, IValidator<LegalDocumentUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor, IBus bus)
           : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
            _bus = bus;
        }

        protected override IQueryable<LegalDocument> IncludeRelatedEntities(LegalDocumentSearchObject? search, IQueryable<LegalDocument> query = null)
            => query.Include(d => d.Category);

        protected override IQueryable<LegalDocument> ApplyFilters(IQueryable<LegalDocument> query, LegalDocumentSearchObject? search)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
                query = query.Where(d => d.Name.ToLower().Contains(search.Name.ToLower()));
            if (search?.CategoryId is int cid)
                query = query.Where(d => d.CategoryId == cid);
            return query;
        }

        public override async Task<LegalDocumentResponse> InsertAsync(LegalDocumentInsertRequest request)
        {
            ValidatePdf(request.FileBase64);
            var response = await base.InsertAsync(request);
            await _bus.PubSub.PublishAsync(new LegalDocumentUploaded { DocumentId = response.Id });
            return response;
        }

        private static void ValidatePdf(string fileBase64)
        {
            byte[] bytes;
            try
            {
                bytes = Convert.FromBase64String(fileBase64);
            }
            catch (FormatException)
            {
                throw new BusinessException("Sadržaj datoteke nije validan.");
            }

            // PDF signature: 0x25 0x50 0x44 0x46  ("%PDF")
            if (bytes.Length < 4 ||
                bytes[0] != 0x25 || bytes[1] != 0x50 || bytes[2] != 0x44 || bytes[3] != 0x46)
            {
                throw new BusinessException("Dozvoljene su samo PDF datoteke.");
            }
        }

        // List view never needs the file bytes — project to the DTO in the query so SQL
        // does not pull the large FileBase64 column for every row.
        public override async Task<PageResult<LegalDocumentResponse>> GetAllAsync(LegalDocumentSearchObject? search = null)
        {
            search ??= new LegalDocumentSearchObject();

            var query = ApplyFilters(_dbContext.Set<LegalDocument>(), search);

            int? totalCount = null;
            if (search.IncludeTotalCount != false)
                totalCount = await query.CountAsync();

            if (!string.IsNullOrWhiteSpace(search.SortBy))
                query = query.OrderBy(search.SortBy);

            var page = search.Page ?? 1;
            var pageSize = Math.Clamp(search.PageSize ?? 20, 1, 100);

            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(d => new LegalDocumentResponse
                {
                    Id = d.Id,
                    Name = d.Name,
                    CategoryName = d.Category.Name,
                    UploadedAt = d.UploadedAt,
                })
                .ToListAsync();

            return new PageResult<LegalDocumentResponse>
            {
                Items = items,
                TotalCount = totalCount,
            };
        }

        protected override LegalDocument MapInsertRequestToEntity(LegalDocumentInsertRequest request)
        {
            var entity = base.MapInsertRequestToEntity(request);
            entity.UploadedByAdminId = _userAccessor.GetUserId()
                ?? throw new UnauthorizedAccessException("Korisnik nije autentificiran.");
            entity.UploadedAt = DateTime.UtcNow;
            return entity;
        }

        public async Task<(byte[] Bytes, string FileName)> GetFileForDownloadAsync(int id)
        {
            var doc = await _dbContext.Set<LegalDocument>().FirstOrDefaultAsync(d => d.Id == id) ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(LegalDocument), id));
            return (Convert.FromBase64String(doc.FileBase64), $"{doc.Name}.pdf");
        }
    }
}
