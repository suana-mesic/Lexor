using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    public partial class LexorDbContext
    {
        private void CreateConfiguration(ModelBuilder modelBuilder)
        {
            // ===== User =====
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique()
                .HasFilter("[Username] <> ''");   // unique when != ''

            // ===== UserRole (M2M User <-> Role) =====
            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<UserRole>()
                .HasIndex(ur => new { ur.UserId, ur.RoleId })
                .IsUnique();

            // ===== RefreshToken =====
            modelBuilder.Entity<RefreshToken>()
                .HasOne(rt => rt.User)
                .WithMany(u => u.RefreshTokens)
                .HasForeignKey(rt => rt.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== Employee (1-0..1 User) =====
            modelBuilder.Entity<Employee>()
                .HasOne(e => e.User)
                .WithOne(u => u.Employee!)
                .HasForeignKey<Employee>(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Employee>()
                .HasOne(e => e.City)
                .WithMany(c => c.Employees)
                .HasForeignKey(e => e.CityId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Employee>()
                .HasOne(e => e.Department)
                .WithMany(d => d.Employees)
                .HasForeignKey(e => e.DepartmentId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Employee>()
                .HasOne(e => e.Position)
                .WithMany(p => p.Employees)
                .HasForeignKey(e => e.PositionId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== Contract =====
            modelBuilder.Entity<Contract>()
                .HasOne(c => c.Employee)
                .WithMany(e => e.Contracts)
                .HasForeignKey(c => c.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Contract>()
                .HasOne(c => c.ContractType)
                .WithMany(ct => ct.Contracts)
                .HasForeignKey(c => c.ContractTypeId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== RfidCard =====
            modelBuilder.Entity<RfidCard>()
                .HasOne(rc => rc.Employee)
                .WithMany(e => e.RfidCards)
                .HasForeignKey(rc => rc.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<RfidCard>()
                .HasIndex(rc => rc.Uid)
                .IsUnique();

            // ===== Attendance =====
            modelBuilder.Entity<Attendance>()
                .HasOne(a => a.Employee)
                .WithMany(e => e.Attendances)
                .HasForeignKey(a => a.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Attendance>()
                .HasOne(a => a.RfidCard)
                .WithMany(rc => rc.Attendances)
                .HasForeignKey(a => a.RfidCardId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Attendance>()
                .HasOne(a => a.UpdatedByUser)
                .WithMany()
                .HasForeignKey(a => a.UpdatedByUserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Attendance>()
                .HasIndex(a => new { a.EmployeeId, a.Date })
                .IsUnique();

            // ===== City =====
            modelBuilder.Entity<City>()
                .HasOne(c => c.Country)
                .WithMany(co => co.Cities)
                .HasForeignKey(c => c.CountryId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== LeaveRequest =====
            modelBuilder.Entity<LeaveRequest>()
                .HasOne(lr => lr.Employee)
                .WithMany(e => e.LeaveRequests)
                .HasForeignKey(lr => lr.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<LeaveRequest>()
                .HasOne(lr => lr.LeaveType)
                .WithMany(lt => lt.LeaveRequests)
                .HasForeignKey(lr => lr.LeaveTypeId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<LeaveRequest>()
                .HasOne(lr => lr.ApprovedByAdmin)
                .WithMany()
                .HasForeignKey(lr => lr.ApprovedByAdminId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<LeaveRequest>()
                .HasOne(lr => lr.RejectedByAdmin)
                .WithMany()
                .HasForeignKey(lr => lr.RejectedByAdminId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== SalarySlip =====
            modelBuilder.Entity<SalarySlip>()
                .HasOne(ss => ss.Employee)
                .WithMany(e => e.SalarySlips)
                .HasForeignKey(ss => ss.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<SalarySlip>()
                .HasOne(ss => ss.PayrollSettings)
                .WithMany(ps => ps.SalarySlips)
                .HasForeignKey(ss => ss.PayrollSettingsId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SalarySlip>()
                .HasOne(ss => ss.MarkedAsPaidByAdmin)
                .WithMany()
                .HasForeignKey(ss => ss.MarkedAsPaidByAdminId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SalarySlip>()
                .HasIndex(ss => new { ss.EmployeeId, ss.Year, ss.Month })
                .IsUnique();

            // ===== SalarySlipItem =====
            modelBuilder.Entity<SalarySlipItem>()
                .HasOne(ssi => ssi.SalarySlip)
                .WithMany(ss => ss.Items)
                .HasForeignKey(ssi => ssi.SalarySlipId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== LegalDocument =====
            modelBuilder.Entity<LegalDocument>()
                .HasOne(ld => ld.Category)
                .WithMany(c => c.LegalDocuments)
                .HasForeignKey(ld => ld.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<LegalDocument>()
                .HasOne(ld => ld.UploadedByAdmin)
                .WithMany()
                .HasForeignKey(ld => ld.UploadedByAdminId)
                .OnDelete(DeleteBehavior.Restrict);

            // ===== LegalDocumentChunk =====
            modelBuilder.Entity<LegalDocumentChunk>()
                .HasOne(c => c.LegalDocument)
                .WithMany(d => d.Chunks)
                .HasForeignKey(c => c.LegalDocumentId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== ChatConversation =====
            modelBuilder.Entity<ChatConversation>()
                .HasOne(cc => cc.Employee)
                .WithMany(e => e.ChatConversations)
                .HasForeignKey(cc => cc.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== ChatMessage =====
            modelBuilder.Entity<ChatMessage>()
                .HasOne(cm => cm.ChatConversation)
                .WithMany(cc => cc.Messages)
                .HasForeignKey(cm => cm.ChatConversationId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== Notification =====
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.Employee)
                .WithMany(e => e.Notifications)
                .HasForeignKey(n => n.EmployeeId)
                .OnDelete(DeleteBehavior.Cascade);

            // ===== AuditLog =====
            modelBuilder.Entity<AuditLog>()
                .HasOne(al => al.AdminUser)
                .WithMany()
                .HasForeignKey(al => al.AdminUserId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
