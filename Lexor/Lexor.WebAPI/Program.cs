using Lexor.Services.Database;
using Microsoft.EntityFrameworkCore;
using DotNetEnv;
using Scalar.AspNetCore;
using Lexor.Services;
using Mapster;
using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Services.Validators;
using Lexor.Model.Responses;

Env.TraversePath().Load();
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

builder.Services.AddDbContext<LexorDbContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi

builder.Services.AddMapster();

TypeAdapterConfig<RoleUpdateRequest, Role>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<CityUpdateRequest, City>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<CountryUpdateRequest, Country>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<DepartmentUpdateRequest, Department>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<PositionUpdateRequest, Position>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<ContractTypeUpdateRequest, ContractType>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LegalDocumentCategoryUpdateRequest, LegalDocumentCategory>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LeaveTypeUpdateRequest, LeaveType>.NewConfig().IgnoreNullValues(true);

TypeAdapterConfig<City, CityResponse>.NewConfig().Map(dest => dest.CountryName, src => src.Country != null ? src.Country.Name : null);

builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IDepartmentService, DepartmentService>();
builder.Services.AddScoped<IPositionService, PositionService>();
builder.Services.AddScoped<IContractTypeService, ContractTypeService>();
builder.Services.AddScoped<ILegalDocumentCategoryService, LegalDocumentCategoryService>();
builder.Services.AddScoped<ILeaveTypeService, LeaveTypeService>();

builder.Services.AddScoped<IValidator<CountryInsertRequest>, CountriesInsertValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<RoleInsertRequest>, RoleInsertValidator>();
builder.Services.AddScoped<IValidator<DepartmentInsertRequest>, DepartmentInsertValidator>();
builder.Services.AddScoped<IValidator<PositionInsertRequest>, PositionInsertValidator>();
builder.Services.AddScoped<IValidator<ContractTypeInsertRequest>, ContractTypeInsertValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentCategoryInsertRequest>, LegalDocumentCategoryInsertValidator>();
builder.Services.AddScoped<IValidator<LeaveTypeInsertRequest>, LeaveTypeInsertValidator>();

builder.Services.AddScoped<IValidator<CountryUpdateRequest>, CountriesUpdateValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();
builder.Services.AddScoped<IValidator<RoleUpdateRequest>, RoleUpdateValidator>();
builder.Services.AddScoped<IValidator<DepartmentUpdateRequest>, DepartmentUpdateValidator>();
builder.Services.AddScoped<IValidator<PositionUpdateRequest>, PositionUpdateValidator>();
builder.Services.AddScoped<IValidator<ContractTypeUpdateRequest>, ContractTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentCategoryUpdateRequest>, LegalDocumentCategoryUpdateValidator>();
builder.Services.AddScoped<IValidator<LeaveTypeUpdateRequest>, LeaveTypeUpdateValidator>();


builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
