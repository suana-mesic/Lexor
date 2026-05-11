using DotNetEnv;
using FluentValidation;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Model.SearchObjects;
using Lexor.Services;
using Lexor.Services.Access;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Lexor.Services.LeaveStateMachine;
using Lexor.Services.Validators;
using Lexor.WebAPI;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using System.Text;

Env.TraversePath().Load();
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

builder.Services.AddDbContext<LexorDbContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi

builder.Services.AddMapster();

builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<ICryptoService, CryptoService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IAuthenticatedUserAccessor, AuthenticatedUserAccessor>();


TypeAdapterConfig<RoleUpdateRequest, Role>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<CityUpdateRequest, City>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<CountryUpdateRequest, Country>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<DepartmentUpdateRequest, Department>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<PositionUpdateRequest, Position>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<ContractTypeUpdateRequest, ContractType>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LegalDocumentCategoryUpdateRequest, LegalDocumentCategory>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LeaveTypeUpdateRequest, LeaveType>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<EmployeeUpdateRequest, Employee>.NewConfig().IgnoreNullValues(true).Ignore(dest => dest.User).Ignore(dest => dest.Contracts);
TypeAdapterConfig<EmployeeInsertRequest, Employee>.NewConfig().IgnoreNullValues(true).Ignore(dest => dest.User).Ignore(dest => dest.Contracts);
TypeAdapterConfig<EmployeeUpdateRequest.UserUpdateRequest, User>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<ContractUpdateRequest, Contract>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<RFIDUpdateRequest, RfidCard>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<PayrollSettingsUpdateRequest, PayrollSettings>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<AttendanceUpdateRequest, Attendance>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LeaveUpdateRequest, Leave>.NewConfig().IgnoreNullValues(true);


TypeAdapterConfig<City, CityResponse>.NewConfig().Map(dest => dest.CountryName, src => src.Country != null ? src.Country.Name : null);

builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IDepartmentService, DepartmentService>();
builder.Services.AddScoped<IPositionService, PositionService>();
builder.Services.AddScoped<ISalarySlipService, SalarySlipService>();
builder.Services.AddScoped<IContractTypeService, ContractTypeService>();
builder.Services.AddScoped<ILegalDocumentCategoryService, LegalDocumentCategoryService>();
builder.Services.AddScoped<ILeaveTypeService, LeaveTypeService>();
builder.Services.AddScoped<IEmployeeService, EmployeeService>();
builder.Services.AddScoped<IContractService, ContractService>();
builder.Services.AddScoped<IRFIDService, RFIDService>();
builder.Services.AddScoped<IPayrollSettingsService, PayrollSettingsService>();
builder.Services.AddScoped<IAttendanceService, AttendanceService>();

builder.Services.AddScoped<BaseLeaveState>();
builder.Services.AddScoped<InitialLeaveState>();
builder.Services.AddScoped<PendingLeaveState>();
builder.Services.AddScoped<ApprovedLeaveState>();
builder.Services.AddScoped<RejectedLeaveState>();
builder.Services.AddScoped<CancelledLeaveState>();
builder.Services.AddScoped<ILeaveService, LeaveService>();

builder.Services.AddScoped<IValidator<LoginRequest>, LoginRequestValidator>();

builder.Services.AddScoped<IValidator<CountryInsertRequest>, CountriesInsertValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<RoleInsertRequest>, RoleInsertValidator>();
builder.Services.AddScoped<IValidator<DepartmentInsertRequest>, DepartmentInsertValidator>();
builder.Services.AddScoped<IValidator<PositionInsertRequest>, PositionInsertValidator>();
builder.Services.AddScoped<IValidator<ContractTypeInsertRequest>, ContractTypeInsertValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentCategoryInsertRequest>, LegalDocumentCategoryInsertValidator>();
builder.Services.AddScoped<IValidator<LeaveTypeInsertRequest>, LeaveTypeInsertValidator>();
builder.Services.AddScoped<IValidator<EmployeeInsertRequest>, EmployeeInsertValidator>();
builder.Services.AddScoped<IValidator<ContractInsertRequest>, ContractInsertValidator>();
builder.Services.AddScoped<IValidator<RFIDInsertRequest>, RFIDInsertValidator>();
builder.Services.AddScoped<IValidator<PayrollSettingsInsertRequest>, PayrollSettingsInsertValidator>();
builder.Services.AddScoped<IValidator<AttendanceInsertRequest>, AttendanceInsertValidator>();
builder.Services.AddScoped<IValidator<LeaveInsertRequest>, LeaveInsertValidator>();

builder.Services.AddScoped<IValidator<CountryUpdateRequest>, CountriesUpdateValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();
builder.Services.AddScoped<IValidator<RoleUpdateRequest>, RoleUpdateValidator>();
builder.Services.AddScoped<IValidator<DepartmentUpdateRequest>, DepartmentUpdateValidator>();
builder.Services.AddScoped<IValidator<PositionUpdateRequest>, PositionUpdateValidator>();
builder.Services.AddScoped<IValidator<ContractTypeUpdateRequest>, ContractTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentCategoryUpdateRequest>, LegalDocumentCategoryUpdateValidator>();
builder.Services.AddScoped<IValidator<LeaveTypeUpdateRequest>, LeaveTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<EmployeeUpdateRequest>, EmployeeUpdateValidator>();
builder.Services.AddScoped<IValidator<ContractUpdateRequest>, ContractUpdateValidator>();
builder.Services.AddScoped<IValidator<RFIDUpdateRequest>, RFIDUpdateValidator>();
builder.Services.AddScoped<IValidator<PayrollSettingsUpdateRequest>, PayrollSettingsUpdateValidator>();
builder.Services.AddScoped<IValidator<AttendanceUpdateRequest>, AttendanceUpdateValidator>();
builder.Services.AddScoped<IValidator<LeaveUpdateRequest>, LeaveUpdateValidator>();
builder.Services.AddScoped<IValidator<LeaveRejectRequest>, LeaveRejectValidator>();
builder.Services.AddScoped<IValidator<SalarySlipCalculationRequest>, SalarySlipCalculationInsertValidator>();
builder.Services.AddScoped<IValidator<SalarySlipSingleRecalculationRequest>, SalarySlipSingleRecalculationValidator>();
builder.Services.AddScoped<IValidator<SalarySlipAllRecalculationRequest>, SalarySlipAllRecalculationValidator>();
builder.Services.AddScoped<IValidator<SalarySlipPayAllRequest>, SalarySlipPayAllValidator>();
builder.Services.AddScoped<IValidator<SalarySlipPaySingleRequest>, SalarySlipPaySingleValidator>();


//adds Bearer in Scalar
//adds requirement on each endpoint (Scalar shows it as padlock icon)
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer<BearerSecuritySchemeTransformer>();
});

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(o =>
{
    o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidIssuer = builder.Configuration["JwtToken:Issuer"],
        ValidAudience = builder.Configuration["JwtToken:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(builder.Configuration["JwtToken:SecretKey"] ?? string.Empty)),
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ClockSkew = TimeSpan.Zero
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithPreferredScheme("Bearer")
               .WithHttpBearerAuthentication(bearer =>
               {
                   bearer.Token = "";
               });
    });
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

app.Run();
