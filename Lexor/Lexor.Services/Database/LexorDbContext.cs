using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    public partial class LexorDbContext : DbContext
    {
        public LexorDbContext(DbContextOptions<LexorDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }

        public DbSet<Country> Countries { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<Department> Departments { get; set; }
        public DbSet<Position> Positions { get; set; }
        public DbSet<ContractType> ContractTypes { get; set; }
        public DbSet<LeaveType> LeaveTypes { get; set; }
        public DbSet<LegalDocumentCategory> LegalDocumentCategories { get; set; }

        public DbSet<Employee> Employees { get; set; }
        public DbSet<Contract> Contracts { get; set; }
        public DbSet<RfidCard> RfidCards { get; set; }
        public DbSet<Attendance> Attendances { get; set; }
        public DbSet<Leave> Leaves { get; set; }
        public DbSet<PayrollSettings> PayrollSettings { get; set; }
        public DbSet<SalarySlip> SalarySlips { get; set; }
        public DbSet<SalarySlipItem> SalarySlipItems { get; set; }
        public DbSet<LegalDocument> LegalDocuments { get; set; }
        public DbSet<LegalDocumentChunk> LegalDocumentChunks { get; set; }
        public DbSet<ChatConversation> ChatConversations { get; set; }
        public DbSet<ChatMessage> ChatMessages { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<News> News { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            CreateConfiguration(modelBuilder);
            CreateSeed(modelBuilder);
        }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            RecalculateAttendanceWorkedHours();
            return base.SaveChangesAsync(cancellationToken);
        }

        public override int SaveChanges()
        {
            RecalculateAttendanceWorkedHours();
            return base.SaveChanges();
        }

        private void RecalculateAttendanceWorkedHours()
        {
            foreach (var entry in ChangeTracker.Entries<Attendance>())
            {
                if (entry.State is not (EntityState.Added or EntityState.Modified))
                    continue;

                var a = entry.Entity;
                if (a.DateTimeEntered.HasValue && a.DateTimeLeft.HasValue
                    && a.DateTimeLeft.Value > a.DateTimeEntered.Value)
                {
                    var hours = (decimal)(a.DateTimeLeft.Value - a.DateTimeEntered.Value).TotalHours;
                    a.WorkedHours = Math.Round(hours, 2);
                }
                else
                {
                    a.WorkedHours = null;
                }
            }
        }
    }
}
