using Lexor.Model.Constants;
using Microsoft.EntityFrameworkCore;
using System;

namespace Lexor.Services.Database
{
    public partial class LexorDbContext
    {
        private void CreateSeed(ModelBuilder modelBuilder)
        {
            var seedDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

            // ===== Roles =====
            modelBuilder.Entity<Role>().HasData(
                new Role { Id = 1, Name = RoleNames.HrManager,     Description = "HR menadžer - uposlenici, odsustva, izvještaji, predikcija", CreatedAt = seedDate, IsActive = true },
                new Role { Id = 2, Name = RoleNames.Employee,      Description = "Pristup mobilnoj aplikaciji", CreatedAt = seedDate, IsActive = true },
                new Role { Id = 3, Name = RoleNames.Accounting,    Description = "Računovodstvo - obračun plata i platni izvještaji", CreatedAt = seedDate, IsActive = true },
                new Role { Id = 4, Name = RoleNames.Administrator, Description = "Administrator sistema", CreatedAt = seedDate, IsActive = true }
            );

            // ===== Country =====
            modelBuilder.Entity<Country>().HasData(
                new Country { Id = 1, Name = "Bosna i Hercegovina" }
            );

            // ===== Cities =====
            modelBuilder.Entity<City>().HasData(
                new City { Id = 1, Name = "Sarajevo",   CountryId = 1 },
                new City { Id = 2, Name = "Mostar",     CountryId = 1 },
                new City { Id = 3, Name = "Tuzla",      CountryId = 1 },
                new City { Id = 4, Name = "Zenica",     CountryId = 1 },
                new City { Id = 5, Name = "Banja Luka", CountryId = 1 }
            );

            // ===== Departments =====
            modelBuilder.Entity<Department>().HasData(
                new Department { Id = 1, Name = "HR" },
                new Department { Id = 2, Name = "IT" },
                new Department { Id = 3, Name = "Prodaja" },
                new Department { Id = 4, Name = "Produkcija" },
                new Department { Id = 5, Name = "Finansije" }
            );

            // ===== Positions (each tied to its department) =====
            modelBuilder.Entity<Position>().HasData(
                new Position { Id = 1, Name = "HR menadžer", DepartmentId = 1 },
                new Position { Id = 2, Name = "Specijalista za zapošljavanje", DepartmentId = 1 },
                new Position { Id = 3, Name = "Programer", DepartmentId = 2 },
                new Position { Id = 4, Name = "DevOps inženjer", DepartmentId = 2 },
                new Position { Id = 5, Name = "Predstavnik prodaje", DepartmentId = 3 },
                new Position { Id = 6, Name = "Menadžer proizvodnje", DepartmentId = 4 },
                new Position { Id = 7, Name = "Računovođa", DepartmentId = 5 }
            );

            // ===== ContractTypes =====
            modelBuilder.Entity<ContractType>().HasData(
                new ContractType { Id = 1, Name = "Neodređeno" , EndDateRequired = false},
                new ContractType { Id = 2, Name = "Određeno", EndDateRequired = true },
                new ContractType { Id = 3, Name = "Stručna praksa", EndDateRequired = true }
            );

            // ===== LeaveTypes =====
            modelBuilder.Entity<LeaveType>().HasData(
                new LeaveType { Id = 1, Name = "Godišnji odmor",     IsPaid = true },
                new LeaveType { Id = 2, Name = "Bolovanje",          IsPaid = true },
                new LeaveType { Id = 3, Name = "Plaćeno odsustvo",   IsPaid = true },
                new LeaveType { Id = 4, Name = "Neplaćeno odsustvo", IsPaid = false }
            );

            // ===== LegalDocumentCategories =====
            // Categories describe the TYPE of document, not its subject, so any legal document
            // fits one of them regardless of topic.
            modelBuilder.Entity<LegalDocumentCategory>().HasData(
                new LegalDocumentCategory { Id = 1, Name = "Zakon" },
                new LegalDocumentCategory { Id = 2, Name = "Pravilnik" },
                new LegalDocumentCategory { Id = 3, Name = "Dopuna/izmjena" }
            );

            // ===== PayrollSettings (FBiH default rates 2026) =====
            modelBuilder.Entity<PayrollSettings>().HasData(
                new PayrollSettings
                {
                    Id = 1,
                    ValidFrom = seedDate,
                    ValidTo = null,
                    OvertimeMultiplier = 1.30m,
                    PersonalDeduction = 300m,
                    PioMioRate = 17m,
                    HealthInsuranceRate = 12.5m,
                    UnemploymentRate = 1.5m,
                    IncomeTaxRate = 10m
                }
            );
        }
    }
}
