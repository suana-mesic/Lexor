using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.LeaveStateMachine;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    /// <summary>
    /// Seeds demo business data (an admin account plus employees, contracts, RFID cards,
    /// three years of attendance history and roughly a thousand leave records) on startup.
    /// Reference tables (roles, departments, positions, leave types, ...) are seeded
    /// separately via HasData in <see cref="LexorDbContext"/>. This runs once and is a
    /// no-op when employees already exist, so it is safe to call on every application start.
    ///
    /// The history is shaped for absence prediction with PER-EMPLOYEE seasonality:
    ///  - each employee has their own vacation month (annual leave lands there every year),
    ///  - each employee has their own sick-peak month (recurring sick leaves land there),
    ///  - sick leaves are multi-day blocks (illness lasts), plus occasional random ones,
    ///  - a small unexcused-absence noise (with Monday/Friday and streak effects) adds
    ///    realistic unpredictability without overwhelming the seasonal patterns.
    /// Three full yearly cycles make the seasonality learnable both for the per-day
    /// classifier and for time-series (SSA) forecasting.
    /// </summary>
    public static class DataSeeder
    {
        // Three-year history window ending close to "today" so the app looks alive.
        private static readonly DateOnly HistoryStart = new(2023, 7, 1);
        private static readonly DateOnly HistoryEnd = new(2026, 7, 24);

        private const int EmployeeCount = 30;

        // Unexcused-absence model (deliberately small so seasonal patterns dominate).
        private const double MondayFridayEffect = 0.015;
        private const double StreakEffect = 0.25; // absent yesterday -> likelier absent today

        // Monthly probabilities for the random (non-seasonal) leave noise. Tuned via
        // simulation so the per-employee seasonal patterns stay dominant and a well-built
        // classifier can reach F1 >= 0.8 on this data.
        private const double RandomSickChancePerMonth = 0.10;
        private const double OtherLeaveChancePerMonth = 0.40;
        private const double MiniVacationChancePerMonth = 0.12;

        // Each position belongs to exactly one department (must match LexorSeed reference data).
        private static readonly (int DeptId, int PosId, decimal BaseSalary)[] Roles =
        {
            (1, 1, 3200m), // HR menadžer
            (1, 2, 1900m), // Specijalista za zapošljavanje
            (2, 3, 2600m), // Programer
            (2, 4, 2800m), // DevOps inženjer
            (3, 5, 2000m), // Predstavnik prodaje
            (4, 6, 2900m), // Menadžer proizvodnje
            (5, 7, 2400m), // Računovođa
        };

        private static readonly string[] FirstNames =
        {
            "Amina", "Emir", "Lejla", "Tarik", "Nadina", "Adnan", "Ivana", "Damir",
            "Selma", "Haris", "Amila", "Kenan", "Merima", "Vedad", "Azra", "Faruk",
            "Dženana", "Nedim", "Ajla", "Mirza", "Belma", "Edin", "Lamija", "Armin",
            "Sara", "Benjamin", "Esma", "Dino", "Hana", "Amar"
        };

        private static readonly string[] LastNames =
        {
            "Hodžić", "Kovačević", "Begić", "Delić", "Suljić", "Mujić", "Marić", "Hadžić",
            "Softić", "Musić", "Halilović", "Imamović", "Dedić", "Kadić", "Omerović", "Sinanović",
            "Čaušević", "Beganović", "Handžić", "Zukić", "Alić", "Fejzić", "Ramić", "Turković",
            "Pirić", "Salkić", "Mehić", "Đurić", "Hasić", "Burić"
        };

        public static async Task SeedAsync(LexorDbContext db, ICryptoService crypto)
        {
            // Business data is generated only for a fresh database; reference data lives in HasData.
            if (await db.Employees.AnyAsync())
                return;

            // Deterministic randomness so a fresh seed always produces the same data set.
            var rng = new Random(20260101);

            // ----- Admin (desktop) account -----
            var admin = BuildUser(crypto, "Amela", "Admin", "admin@lexor.ba", "061100100", "Admin123!");
            admin.UserRoles.Add(new UserRole { RoleId = 1, DateAssigned = DateTime.UtcNow });
            db.Users.Add(admin);
            await db.SaveChangesAsync(); // persist so admin.Id can be used as CreatedByUserId

            for (var i = 0; i < EmployeeCount; i++)
            {
                var first = FirstNames[i];
                var last = LastNames[i];
                var role = Roles[i % Roles.Length];

                var email = $"{Asciify(first)}.{Asciify(last)}@lexor.ba";
                var user = BuildUser(crypto, first, last, email, RandomPhone(rng), "Test123!");
                user.ProfileImageBase64 = SeedAvatars.Base64[i];
                user.UserRoles.Add(new UserRole { RoleId = 2, DateAssigned = HistoryStart.ToDateTime(TimeOnly.MinValue) });

                // Personal seasonality profile. The formulas spread months evenly across
                // employees and can never make both peaks land on the same month.
                var vacationMonth = 1 + (i * 5) % 12;
                var sickPeakMonth = 1 + (i * 7 + 3) % 12;
                var unexcusedBaseRate = 0.004 + rng.NextDouble() * 0.008; // 0.4-1.2%

                // Hired before the history window so every employee has full 3-year history.
                var hire = new DateTime(rng.Next(2019, 2023), rng.Next(1, 13), rng.Next(1, 28));
                var contractTypeId = i % 5 == 0 ? 2 : 1; // every fifth employee is on a fixed-term contract

                var employee = new Employee
                {
                    User = user,
                    DateOfBirth = new DateTime(rng.Next(1980, 2001), rng.Next(1, 13), rng.Next(1, 28)),
                    Address = $"Ulica {rng.Next(1, 120)}, br. {rng.Next(1, 60)}",
                    CityId = (i % 5) + 1,
                    DepartmentId = role.DeptId,
                    PositionId = role.PosId,
                    HireDate = hire,
                    IsActive = true,
                    CreatedAt = hire,
                    CreatedByUserId = admin.Id
                };

                employee.Contracts.Add(new Contract
                {
                    ContractTypeId = contractTypeId,
                    StartDate = hire,
                    // Fixed-term contracts end after the seeded history so payroll stays simple.
                    EndDate = contractTypeId == 1 ? null : new DateTime(2027, 12, 31),
                    BrutoSalary = role.BaseSalary + rng.Next(-2, 4) * 100m,
                    WorkHoursPerDay = 8,
                    CreatedAt = hire,
                    CreatedByUserId = admin.Id
                });

                var card = new RfidCard
                {
                    Uid = $"RFID-{i + 1:D4}",
                    AssignedAt = hire,
                    IsActive = true
                };
                employee.RfidCards.Add(card);

                var leaveRanges = BuildLeaves(employee, admin.Id, vacationMonth, sickPeakMonth, rng);
                BuildAttendance(employee, card, leaveRanges, unexcusedBaseRate, rng);

                db.Employees.Add(employee);
            }

            await db.SaveChangesAsync();
        }

        // Builds a user with a freshly salted PBKDF2 password hash and an already-activated account.
        private static User BuildUser(ICryptoService crypto, string first, string last,
                                      string email, string phone, string password)
        {
            var salt = crypto.GenerateSalt();
            return new User
            {
                FirstName = first,
                LastName = last,
                Email = email,
                Username = email,
                PhoneNumber = phone,
                PasswordSalt = salt,
                PasswordHash = crypto.GenerateHash(password, salt),
                IsActive = true,
                IsCodeActivated = true,
                CreatedAt = DateTime.UtcNow
            };
        }

        // Walks month by month through the history window and generates this employee's leaves:
        // an annual-leave block in their personal vacation month, recurring multi-day sick
        // blocks in their personal sick-peak month, plus random short leaves as noise.
        private static List<(DateOnly From, DateOnly To)> BuildLeaves(Employee employee, int adminId,
                                                                      int vacationMonth, int sickPeakMonth,
                                                                      Random rng)
        {
            var ranges = new List<(DateOnly From, DateOnly To)>();

            var month = new DateOnly(HistoryStart.Year, HistoryStart.Month, 1);
            while (month <= HistoryEnd)
            {
                if (month.Month == vacationMonth && rng.NextDouble() < 0.90)
                    AddLeave(employee, ranges, adminId, rng, month, leaveTypeId: 1,
                             reason: "Godišnji odmor", minLen: 7, maxLen: 12);
                else if (rng.NextDouble() < MiniVacationChancePerMonth)
                    AddLeave(employee, ranges, adminId, rng, month, leaveTypeId: 1,
                             reason: "Godišnji odmor", minLen: 2, maxLen: 4);

                if (month.Month == sickPeakMonth)
                {
                    // Two to three multi-day sick blocks every year in the personal peak month.
                    var blocks = rng.Next(2, 4);
                    for (var b = 0; b < blocks; b++)
                        AddLeave(employee, ranges, adminId, rng, month, leaveTypeId: 2,
                                 reason: "Bolovanje", minLen: 6, maxLen: 10);
                }
                else if (rng.NextDouble() < RandomSickChancePerMonth)
                {
                    AddLeave(employee, ranges, adminId, rng, month, leaveTypeId: 2,
                             reason: "Bolovanje", minLen: 5, maxLen: 8);
                }

                if (rng.NextDouble() < OtherLeaveChancePerMonth)
                {
                    var paid = rng.NextDouble() < 0.5;
                    AddLeave(employee, ranges, adminId, rng, month,
                             leaveTypeId: paid ? 3 : 4,
                             reason: paid ? "Plaćeno odsustvo" : "Neplaćeno odsustvo",
                             minLen: 1, maxLen: 3);
                }

                month = month.AddMonths(1);
            }

            return ranges;
        }

        // Places one leave of the given length inside the given month, avoiding overlaps
        // with already generated leaves (approved leaves must never overlap).
        private static void AddLeave(Employee employee, List<(DateOnly From, DateOnly To)> ranges,
                                     int adminId, Random rng, DateOnly month, int leaveTypeId,
                                     string reason, int minLen, int maxLen)
        {
            var length = rng.Next(minLen, maxLen + 1);
            var daysInMonth = DateTime.DaysInMonth(month.Year, month.Month);

            DateOnly from = default;
            var placed = false;
            for (var attempt = 0; attempt < 40 && !placed; attempt++)
            {
                var startDay = rng.Next(1, Math.Max(2, daysInMonth - length));
                from = new DateOnly(month.Year, month.Month, startDay);
                placed = !Overlaps(ranges, from, from.AddDays(length - 1))
                         && from >= HistoryStart
                         && from.AddDays(length - 1) <= HistoryEnd;
            }

            if (!placed)
                return; // month too crowded; skip rather than seed invalid overlapping leaves

            var to = from.AddDays(length - 1);

            employee.Leaves.Add(new Leave
            {
                LeaveTypeId = leaveTypeId,
                DateFrom = from,
                DateTo = to,
                NumberOfDays = length,
                Reason = reason,
                State = nameof(CompletedLeaveState),
                CreatedAt = from.ToDateTime(TimeOnly.MinValue).AddDays(-3),
                ApprovedByAdminId = adminId,
                ApprovedAt = from.ToDateTime(TimeOnly.MinValue).AddDays(-2),
                CompletedAt = to.ToDateTime(TimeOnly.MinValue).AddDays(1)
            });

            ranges.Add((from, to));
        }

        private static bool Overlaps(List<(DateOnly From, DateOnly To)> ranges, DateOnly from, DateOnly to)
            => ranges.Any(r => from <= r.To && to >= r.From);

        // Transliterates Bosnian diacritics to ASCII so display names can keep them
        // (e.g. "Marić") while the derived e-mail/username stays plain ("ivana.maric").
        private static string Asciify(string value)
            => value.ToLowerInvariant()
                .Replace("dž", "dz")
                .Replace("č", "c")
                .Replace("ć", "c")
                .Replace("š", "s")
                .Replace("ž", "z")
                .Replace("đ", "dj");

        // Creates an attendance stamp for every working day in the window, except days covered
        // by a leave or hit by an unexcused absence (small noise with weekday/streak effects).
        private static void BuildAttendance(Employee employee, RfidCard card,
                                            List<(DateOnly From, DateOnly To)> leaves,
                                            double baseRate, Random rng)
        {
            var absentPreviousWorkday = false;

            for (var day = HistoryStart; day <= HistoryEnd; day = day.AddDays(1))
            {
                if (day.DayOfWeek == DayOfWeek.Saturday || day.DayOfWeek == DayOfWeek.Sunday)
                    continue;

                if (leaves.Any(r => day >= r.From && day <= r.To))
                {
                    absentPreviousWorkday = false; // an approved leave resets the unexcused streak
                    continue;
                }

                var probability = baseRate;
                if (day.DayOfWeek is DayOfWeek.Monday or DayOfWeek.Friday)
                    probability += MondayFridayEffect;
                if (absentPreviousWorkday)
                    probability += StreakEffect; // sickness tends to last more than one day

                if (rng.NextDouble() < probability)
                {
                    absentPreviousWorkday = true; // unexcused absence: no attendance stamp
                    continue;
                }

                absentPreviousWorkday = false;

                var enter = day.ToDateTime(new TimeOnly(8, rng.Next(0, 20)));
                var left = day.ToDateTime(new TimeOnly(16, rng.Next(0, 30)));

                employee.Attendances.Add(new Attendance
                {
                    RfidCard = card,
                    Date = day,
                    DateTimeEntered = enter,
                    DateTimeLeft = left,
                    WorkedHours = Math.Round((decimal)(left - enter).TotalHours, 2)
                });
            }
        }

        private static string RandomPhone(Random rng) => $"06{rng.Next(0, 4)}{rng.Next(100000, 999999)}";
    }
}
