using DotNetEnv;
using FluentValidation;
using Lexor.Model.Enums;
using Lexor.Model.Requests;
using Lexor.Model.Responses;
using Lexor.Services;
using Lexor.Services.Access;
using Lexor.Services.Database;
using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.LeaveStateMachine;
using Lexor.Services.StateMachine.SalarySlipStateMachine;
using Lexor.Services.Validators;
using Lexor.WebAPI;
using Lexor.WebAPI.Json;
using Lexor.WebAPI.Auth;
using Lexor.WebAPI.Filters;
using Mapster;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;
using SmartComponents.LocalEmbeddings;
using System.Text;
using System.Threading.RateLimiting;
using Lexor.Services.ML;

Env.TraversePath().Load();
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers(options =>
{
    options.Filters.Add<ExceptionFilter>();
})
.AddJsonOptions(o =>
{
    // Emit all timestamps as UTC with a 'Z' suffix so clients convert them to local time correctly.
    o.JsonSerializerOptions.Converters.Add(new UtcDateTimeConverter());
    o.JsonSerializerOptions.Converters.Add(new UtcNullableDateTimeConverter());
});

builder.Services.AddOptions<GroqOptions>()
    .Bind(builder.Configuration.GetSection("Groq"))
    .Validate(o=>!string.IsNullOrWhiteSpace(o.ApiKey), "Groq:ApiKey je obavezna konfiguracijska vrijednost.")
    .ValidateOnStart(); 

builder.Services.AddOptions<JwtTokenOptions>()
        .Bind(builder.Configuration.GetSection("JwtToken"))
        .Validate(o => !string.IsNullOrWhiteSpace(o.SecretKey), "JwtToken:SecretKey je obavezna konfiguracijska vrijednost.")
        .ValidateOnStart();

builder.Services.AddDbContext<LexorDbContext>(options => options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddMapster();

builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<ICryptoService, CryptoService>();
builder.Services.AddScoped<IAccessManager, AccessManager>();
builder.Services.AddHttpContextAccessor();
// Backing store for IMemoryCache (payroll settings are cached at the service level).
builder.Services.AddMemoryCache();
builder.Services.AddScoped<IAuthenticatedUserAccessor, AuthenticatedUserAccessor>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddSingleton<IFraudDetectionService, FraudDetectionService>();


TypeAdapterConfig<RoleUpdateRequest, Role>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<CityUpdateRequest, City>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<CountryUpdateRequest, Country>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<DepartmentUpdateRequest, Department>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<NewsUpdateRequest, News>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<PositionUpdateRequest, Position>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<ContractTypeUpdateRequest, ContractType>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LegalDocumentCategoryUpdateRequest, LegalDocumentCategory>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LegalDocumentUpdateRequest, LegalDocument>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LeaveTypeUpdateRequest, LeaveType>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<EmployeeUpdateRequest, Employee>.NewConfig().IgnoreNullValues(true).Ignore(dest => dest.User).Ignore(dest => dest.Contracts);
TypeAdapterConfig<EmployeeInsertRequest, Employee>.NewConfig().IgnoreNullValues(true).Ignore(dest => dest.User).Ignore(dest => dest.Contracts);
TypeAdapterConfig<EmployeeUpdateRequest.UserUpdateRequest, User>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<ContractUpdateRequest, Contract>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<RFIDUpdateRequest, RfidCard>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<PayrollSettingsUpdateRequest, PayrollSettings>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<AttendanceUpdateRequest, Attendance>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<LeaveUpdateRequest, Leave>.NewConfig().IgnoreNullValues(true);
TypeAdapterConfig<SalarySlip, SalarySlipResponse>.NewConfig()
    .Map(dest => dest.Status, src =>
        src.State == nameof(PaidSalarySlipState) ? SalarySlipStatus.Paid :
        src.State == nameof(ApprovedSalarySlipState) ? SalarySlipStatus.Approved :
        SalarySlipStatus.Pending);


TypeAdapterConfig<City, CityResponse>.NewConfig().Map(dest => dest.CountryName, src => src.Country != null ? src.Country.Name : null);

TypeAdapterConfig<PayrollSettings, PayrollSettingsResponse>.NewConfig()
    .Map(dest => dest.WorkDaysDescription, src => PayrollSettingsService.MaskToDescription(src.WorkDaysMask));

TypeAdapterConfig<LegalDocument, LegalDocumentResponse>.NewConfig().Map(dest => dest.CategoryName, src => src.Category != null ? src.Category.Name : null);
TypeAdapterConfig<User, UserResponse>.NewConfig().Map(dest => dest.RoleName, src => src.UserRoles.Select(ur => ur.Role.Name).FirstOrDefault());

builder.Services.AddHttpClient();

builder.Services.AddScoped<ICountryService, CountryService>();
builder.Services.AddScoped<ICityService, CityService>();
builder.Services.AddScoped<IRoleService, RoleService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IDepartmentService, DepartmentService>();
builder.Services.AddScoped<INewsService, NewsService>();
builder.Services.AddScoped<IAccountService, AccountService>();
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
builder.Services.AddScoped<ILegalDocumentService, LegalDocumentService>();
builder.Services.AddScoped<ILeaveService, LeaveService>();
builder.Services.AddScoped<IChatService, ChatService>();

builder.Services.AddScoped<BaseLeaveState>();
builder.Services.AddScoped<InitialLeaveState>();
builder.Services.AddScoped<PendingLeaveState>();
builder.Services.AddScoped<ApprovedLeaveState>();
builder.Services.AddScoped<RejectedLeaveState>();
builder.Services.AddScoped<CancelledLeaveState>();
builder.Services.AddScoped<CompletedLeaveState>();
builder.Services.AddScoped<BaseSalarySlipState>();
builder.Services.AddScoped<InitialSalarySlipState>();
builder.Services.AddScoped<PendingSalarySlipState>();
builder.Services.AddScoped<ApprovedSalarySlipState>();
builder.Services.AddScoped<PaidSalarySlipState>();

builder.Services.AddScoped<IValidator<LoginRequest>, LoginRequestValidator>();
builder.Services.AddScoped<IValidator<CountryInsertRequest>, CountriesInsertValidator>();
builder.Services.AddScoped<IValidator<CityInsertRequest>, CityInsertValidator>();
builder.Services.AddScoped<IValidator<RoleInsertRequest>, RoleInsertValidator>();
builder.Services.AddScoped<IValidator<DepartmentInsertRequest>, DepartmentInsertValidator>();
builder.Services.AddScoped<IValidator<PositionInsertRequest>, PositionInsertValidator>();
builder.Services.AddScoped<IValidator<ContractTypeInsertRequest>, ContractTypeInsertValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentCategoryInsertRequest>, LegalDocumentCategoryInsertValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentInsertRequest>, LegalDocumentInsertValidator>();
builder.Services.AddScoped<IValidator<LeaveTypeInsertRequest>, LeaveTypeInsertValidator>();
builder.Services.AddScoped<IValidator<EmployeeInsertRequest>, EmployeeInsertValidator>();
builder.Services.AddScoped<IValidator<ContractInsertRequest>, ContractInsertValidator>();
builder.Services.AddScoped<IValidator<RFIDInsertRequest>, RFIDInsertValidator>();
builder.Services.AddScoped<IValidator<PayrollSettingsInsertRequest>, PayrollSettingsInsertValidator>();
builder.Services.AddScoped<IValidator<AttendanceInsertRequest>, AttendanceInsertValidator>();
builder.Services.AddScoped<IValidator<LeaveInsertRequest>, LeaveInsertValidator>();
builder.Services.AddScoped<IValidator<ActivateAccountRequest>, ActivateAccountValidator>();
builder.Services.AddScoped<IValidator<ForgotPasswordRequest>, ForgotPasswordValidator>();
builder.Services.AddScoped<IValidator<ResetPasswordRequest>, ResetPasswordValidator>();
builder.Services.AddScoped<IValidator<ChangePasswordRequest>, ChangePasswordValidator>();
builder.Services.AddScoped<IValidator<NewsInsertRequest>, NewsInsertValidator>();
builder.Services.AddScoped<IValidator<NewsUpdateRequest>, NewsUpdateValidator>();
builder.Services.AddScoped<IValidator<AccountUpdateRequest>, AccountUpdateValidator>();

builder.Services.AddScoped<IValidator<CountryUpdateRequest>, CountriesUpdateValidator>();
builder.Services.AddScoped<IValidator<CityUpdateRequest>, CityUpdateValidator>();
builder.Services.AddScoped<IValidator<RoleUpdateRequest>, RoleUpdateValidator>();
builder.Services.AddScoped<IValidator<DepartmentUpdateRequest>, DepartmentUpdateValidator>();
builder.Services.AddScoped<IValidator<PositionUpdateRequest>, PositionUpdateValidator>();
builder.Services.AddScoped<IValidator<ContractTypeUpdateRequest>, ContractTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentCategoryUpdateRequest>, LegalDocumentCategoryUpdateValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentUpdateRequest>, LegalDocumentUpdateValidator>();
builder.Services.AddScoped<IValidator<LeaveTypeUpdateRequest>, LeaveTypeUpdateValidator>();
builder.Services.AddScoped<IValidator<EmployeeUpdateRequest>, EmployeeUpdateValidator>();
builder.Services.AddScoped<IValidator<ProfileUpdateRequest>, ProfileUpdateValidator>();
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
builder.Services.AddScoped<IValidator<SalarySlipApproveAllRequest>, SalarySlipApproveAllValidator>();
builder.Services.AddScoped<IValidator<SalarySlipApproveSingleRequest>, SalarySlipApproveSingleValidator>();
builder.Services.AddScoped<IValidator<LegalDocumentInsertRequest>, LegalDocumentInsertValidator>();

builder.Services.AddSingleton<EasyNetQ.IBus>(_ => EasyNetQ.RabbitHutch.CreateBus(builder.Configuration["RabbitMQ:ConnectionString"]));
builder.Services.AddSingleton(new LocalEmbedder());
builder.Services.AddScoped<ILegalDocumentIndexer, LegalDocumentIndexer>();

//adds Bearer in Scalar
//adds requirement on each endpoint (Scalar shows it as padlock icon)
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer<BearerSecuritySchemeTransformer>();
});

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(o =>
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
    })
    .AddScheme<DeviceKeyAuthenticationOptions, DeviceKeyAuthenticationHandler>(
        "DeviceKey",
        options =>
        {
            options.ExpectedKey = builder.Configuration["RfidDeviceApiKey"] ?? string.Empty;
        });

const string CorsPolicy = "LexorCorsPolicy";

builder.Services.AddCors(options =>
{
    options.AddPolicy(CorsPolicy, policy =>
    {
        var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
        policy.WithOrigins(origins)
        .AllowAnyHeader()
        .AllowAnyMethod()
        .AllowCredentials();
    });
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    // Sensitive auth endpoints: max 10 requests / minute per client IP.
    options.AddPolicy("auth", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1)
            }));
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    var db = services.GetRequiredService<LexorDbContext>();

    // Integration tests run in the "Testing" environment against a non-relational in-memory
    // provider, which cannot run migrations, so we migrate and seed only outside of tests.
    if (!app.Environment.IsEnvironment("Testing"))
    {
        var retries = 10;

        while (true)
        {
            try
            {
                db.Database.Migrate();
                break;
            }
            catch when (retries-- > 0)
            {
                await Task.Delay(TimeSpan.FromSeconds(5));  
            }
        }

        var crypto = services.GetRequiredService<ICryptoService>();
        await DataSeeder.SeedAsync(db, crypto);
        // Databases seeded before the thumbnail columns existed get their avatars and
        // announcement banners filled in here.
        await DataSeeder.BackfillProfileThumbnailsAsync(db);
        // Seed a payroll history using the real calculation (respects contracts and settings).
        var salarySlipService = services.GetRequiredService<ISalarySlipService>();
        await PayrollSeeder.SeedAsync(salarySlipService, db);
        // Seed and index the legal-document corpus the HR chatbot answers from.
        var legalDocumentIndexer = services.GetRequiredService<ILegalDocumentIndexer>();
        await LegalDocumentSeeder.SeedAsync(db, legalDocumentIndexer);

        // Train the attendance fraud-detection model and log train/test metrics at startup.
        var fraudDetector = services.GetRequiredService<IFraudDetectionService>();
        await fraudDetector.TrainAsync();
        var fm = fraudDetector.Metrics;
        if (fm != null)
        {
            app.Logger.LogInformation(
                "[FRAUD] TRAIN  F1={F1:F3}  Acc={Acc:F3}  P={P:F3}  R={R:F3}  AUC={Auc:F3}  (n={N}, fraud={Fraud})",
                fm.Train.F1Score, fm.Train.Accuracy, fm.Train.Precision, fm.Train.Recall,
                fm.Train.AreaUnderRocCurve, fm.Train.SampleCount, fm.Train.FraudCount);
            app.Logger.LogInformation(
                "[FRAUD] TEST   F1={F1:F3}  Acc={Acc:F3}  P={P:F3}  R={R:F3}  AUC={Auc:F3}  (n={N}, fraud={Fraud})",
                fm.Test.F1Score, fm.Test.Accuracy, fm.Test.Precision, fm.Test.Recall,
                fm.Test.AreaUnderRocCurve, fm.Test.SampleCount, fm.Test.FraudCount);
        }
    }
}

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.AddPreferredSecuritySchemes(new[] { "Bearer" })
               .AddHttpAuthentication("Bearer", scheme =>
               {
                   scheme.Token = "";
               });
    });
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseCors(CorsPolicy);

app.UseAuthentication();

app.UseAuthorization();

app.UseRateLimiter();

app.MapControllers();

app.Run();
public partial class Program { }