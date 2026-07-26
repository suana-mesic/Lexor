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
using Microsoft.Identity.Client;

namespace Lexor.Services
{
    public class ContractService : BaseCRUDService<Contract, ContractResponse, ContractSearchObject, ContractInsertRequest, ContractUpdateRequest>, IContractService
    {
        public ContractService(LexorDbContext dbContext, IMapper mapper, IValidator<ContractInsertRequest> insertValidator, IValidator<ContractUpdateRequest> updateValidator, IAuthenticatedUserAccessor userAccessor)
            : base(dbContext, mapper, insertValidator, updateValidator, userAccessor)
        {
        }

        protected override IQueryable<Contract> ApplyFilters(IQueryable<Contract> query, ContractSearchObject? search)
        {
            if (search != null)
            {
                if (search.EmployeeId.HasValue)
                {
                    query = query.Where(c => c.EmployeeId == search.EmployeeId);
                }
                if (search.ContractTypeId.HasValue)
                {
                    query = query.Where(c => c.ContractTypeId == search.ContractTypeId);
                }

                var today = DateTime.UtcNow.Date;
                query = search.ActivityStatus switch
                {
                    // "Active" = in effect today (date-derived, no stored flag). "Inactive" = expired or upcoming.
                    ActivityStatus.Active => query.Where(c => c.StartDate.Date <= today
                                                          && (c.EndDate == null || c.EndDate.Value.Date >= today)),
                    ActivityStatus.Inactive => query.Where(c => c.StartDate.Date > today
                                                            || (c.EndDate != null && c.EndDate.Value.Date < today)),
                    ActivityStatus.All => query,
                    null => query,
                    _ => throw new ValidationException("Nevažeći filter statusa aktivnosti.")
                };
            }
            return query;
        }

        protected override IQueryable<Contract> IncludeRelatedEntities(ContractSearchObject? search, IQueryable<Contract> query)
        {
            return query.Include(c => c.ContractType);
        }

        public override async Task<ContractResponse> InsertAsync(ContractInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var employee = await _dbContext.Employees.FirstOrDefaultAsync(e => e.Id == request.EmployeeId);
            if (employee == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), request.EmployeeId));

            if (!employee.IsActive)
                throw new ValidationException("Nije moguće kreirati ugovor za neaktivnog uposlenika.");

            var contractType = await _dbContext.Set<ContractType>()
                .FirstOrDefaultAsync(ct => ct.Id == request.ContractTypeId);

            if (contractType == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(ContractType), request.ContractTypeId));

            if (contractType.EndDateRequired && !request.EndDate.HasValue)
                throw new ValidationException("Datum završetka je obavezan za ovaj tip ugovora.");

            // Reject a contract whose validity period overlaps an existing one for the same employee.
            // Date ranges are the source of truth — there is no stored "active" flag to check.
            var newStart = request.StartDate.Date;
            var overlaps = await _dbContext.Contracts.AnyAsync(c => c.EmployeeId == request.EmployeeId
                && (request.EndDate == null || c.StartDate.Date <= request.EndDate.Value.Date)
                && (c.EndDate == null || c.EndDate.Value.Date >= newStart));
            if (overlaps)
                throw new ValidationException("Period novog ugovora se preklapa s postojećim ugovorom uposlenika.");

            // An employee can have at most one upcoming (future-dated) contract at a time.
            if (newStart > DateTime.UtcNow.Date)
            {
                var hasUpcoming = await _dbContext.Contracts.AnyAsync(c =>
                    c.EmployeeId == request.EmployeeId && c.StartDate.Date > DateTime.UtcNow.Date);
                if (hasUpcoming)
                    throw new ValidationException("Uposlenik već ima zakazan budući ugovor. Uredite ili obrišite ga umjesto dodavanja novog.");
            }

            var entity = _mapper.Map<Contract>(request);
            ApplyCreateAuditFields(entity);
            _dbContext.Contracts.Add(entity);
            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(entity.Id);
        }

        // Closes the current active contract (if any) and inserts a new one in a single
        // transaction. Either both happen or nothing changes — the employee can't end up
        // without an active contract due to a partial failure.
        public async Task<ContractResponse> ReplaceActiveAsync(int employeeId, ContractInsertRequest request)
        {
            // The route owns the employee scope; never trust the body to set who.
            request.EmployeeId = employeeId;

            var validationResult = await _insertValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var employee = await _dbContext.Employees.FirstOrDefaultAsync(e => e.Id == employeeId);
            if (employee == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Employee), employeeId));

            if (!employee.IsActive)
                throw new ValidationException("Nije moguće kreirati ugovor za neaktivnog uposlenika.");

            var contractType = await _dbContext.Set<ContractType>()
                .FirstOrDefaultAsync(ct => ct.Id == request.ContractTypeId)
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(ContractType), request.ContractTypeId));

            if (contractType.EndDateRequired && !request.EndDate.HasValue)
                throw new ValidationException("Datum završetka je obavezan za ovaj tip ugovora.");

            await using var tx = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                // Find the contract that extends into/after the new start date (the one being superseded).
                // Selection is purely date-based — no stored flag involved.
                var newStart = request.StartDate.Date;
                var today = DateTime.UtcNow.Date;

                // An employee can have at most one upcoming contract at a time.
                // Reject here so the user edits the existing upcoming contract instead.
                if (newStart > today)
                {
                    var hasUpcoming = await _dbContext.Contracts.AnyAsync(c =>
                        c.EmployeeId == employeeId && c.StartDate.Date > today);
                    if (hasUpcoming)
                        throw new ValidationException("Uposlenik već ima zakazan budući ugovor. Uredite ili obrišite ga umjesto dodavanja novog.");
                }

                var active = await _dbContext.Contracts
                    .Include(c => c.ContractType)
                    .Where(c => c.EmployeeId == employeeId
                             && c.StartDate.Date < newStart
                             && (
                                 // Standard: contract that overlaps with (or runs up to) the new start date.
                                 (c.EndDate == null || c.EndDate.Value.Date >= newStart)
                                 // Gap recovery: indefinite contract whose EndDate was artificially
                                 // capped by a ReplaceActiveAsync for an upstream contract that was
                                 // since deleted, leaving a gap. Recognised by: Neodređeno type,
                                 // EndDate is set but hasn't passed yet, and it falls before newStart.
                                 || (!c.ContractType.EndDateRequired
                                     && c.EndDate.HasValue
                                     && c.EndDate.Value.Date >= today
                                     && c.EndDate.Value.Date < newStart)
                             ))
                    .OrderByDescending(c => c.StartDate)
                    .FirstOrDefaultAsync();

                if (active != null)
                {
                    if (active.ContractType.EndDateRequired && active.EndDate.HasValue)
                    {
                        // Scenario B — fixed-term ("Određeno") contract: legally immutable.
                        // The new contract must start strictly after the fixed-term expires;
                        // any gap between them is intentional (a break in employment).
                        if (request.StartDate.Date <= active.EndDate.Value.Date)
                            throw new ValidationException(
                                $"Aktivan ugovor 'Određeno' važi do {active.EndDate.Value:dd.MM.yyyy}. " +
                                $"Novi ugovor mora početi najranije {active.EndDate.Value.AddDays(1):dd.MM.yyyy}.");
                        // Leave the fixed-term contract untouched — do not modify its EndDate.
                    }
                    else
                    {
                        // Scenario A — indefinite ("Neodređeno") contract: close it the day before
                        // the new contract starts. No gap in employment history.
                        if (request.StartDate.Date <= active.StartDate.Date)
                            throw new ValidationException("Datum početka novog ugovora mora biti nakon datuma početka trenutnog ugovora.");
                        active.EndDate = request.StartDate.AddDays(-1);
                        ApplyUpdateAuditFields(active);
                    }
                }

                var entity = _mapper.Map<Contract>(request);
                ApplyCreateAuditFields(entity);
                _dbContext.Contracts.Add(entity);

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

        public override async Task DeleteAsync(int id)
        {
            var contract = await _dbContext.Contracts.FirstOrDefaultAsync(c => c.Id == id);
            if (contract == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Contract), id));

            var today = DateTime.UtcNow.Date;

            // Only upcoming contracts (start date in the future) can be deleted.
            if (contract.StartDate.Date <= today)
                throw new ValidationException("Nije moguće obrisati aktivan ili istekao ugovor. Istorija ugovora je samo za čitanje.");

            // When ReplaceActiveAsync added this upcoming contract it set the preceding
            // indefinite contract's EndDate to (this.StartDate - 1 day). Deleting this contract
            // must undo that so the employee doesn't end up with a gap in coverage.
            // We can only do this safely for indefinite-type contracts (EndDateRequired = false)
            // because their EndDate is always artificial — it was never part of the original terms.
            var dayBefore = contract.StartDate.Date.AddDays(-1);
            var preceding = await _dbContext.Contracts
                .Include(c => c.ContractType)
                .Where(c => c.EmployeeId == contract.EmployeeId
                         && c.EndDate.HasValue
                         && c.EndDate.Value.Date == dayBefore
                         && c.StartDate.Date < contract.StartDate.Date
                         && !c.ContractType.EndDateRequired)
                .OrderByDescending(c => c.StartDate)
                .FirstOrDefaultAsync();

            if (preceding != null)
            {
                preceding.EndDate = null;
                ApplyUpdateAuditFields(preceding);
            }

            _dbContext.Contracts.Remove(contract);
            await _dbContext.SaveChangesAsync();
        }

        public override async Task<ContractResponse> UpdateAsync(int id, ContractUpdateRequest request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);
            if (!validationResult.IsValid)
                throw new ValidationException(validationResult.Errors);

            var contract = await _dbContext.Contracts.FirstOrDefaultAsync(c => c.Id == id);
            if (contract == null)
                throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(Contract), id));

            var today = DateTime.UtcNow.Date;

            // Only upcoming contracts (start date strictly in the future) can be edited.
            // Active and expired contracts are read-only — add a new contract to replace an active one.
            if (contract.StartDate.Date <= today)
                throw new ValidationException("Aktivan ili istekao ugovor nije moguće uređivati. Dodajte novi ugovor koji zamjenjuje trenutni.");

            // The updated start date must also remain in the future.
            if (request.StartDate.Date <= today)
                throw new ValidationException("Datum početka budućeg ugovora mora ostati u budućnosti.");

            var contractType = await _dbContext.Set<ContractType>()
                .FirstOrDefaultAsync(ct => ct.Id == request.ContractTypeId)
                ?? throw new NotFoundException(EntityDisplayMessage.NotFound(typeof(ContractType), request.ContractTypeId));

            if (contractType.EndDateRequired && !request.EndDate.HasValue)
                throw new ValidationException("Datum završetka je obavezan za ovaj tip ugovora.");

            // If the start date changed, keep the preceding Neodređeno contract's EndDate in sync.
            // That contract was closed (artificially) when this upcoming contract was created;
            // moving the start date must move that closing date with it.
            var oldStart = contract.StartDate.Date;
            var newStart = request.StartDate.Date;

            _mapper.Map(request, contract);
            ApplyUpdateAuditFields(contract);

            if (oldStart != newStart)
            {
                var preceding = await _dbContext.Contracts
                    .Include(c => c.ContractType)
                    .Where(c => c.EmployeeId == contract.EmployeeId
                             && c.EndDate.HasValue
                             && c.EndDate.Value.Date == oldStart.AddDays(-1)
                             && c.StartDate.Date < newStart
                             && !c.ContractType.EndDateRequired)
                    .OrderByDescending(c => c.StartDate)
                    .FirstOrDefaultAsync();

                if (preceding != null)
                {
                    preceding.EndDate = newStart.AddDays(-1);
                    ApplyUpdateAuditFields(preceding);
                }
            }

            await _dbContext.SaveChangesAsync();

            return await GetByIdAsync(id);
        }
    }
}
