using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.LeaveStateMachine;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    /// <summary>
    /// Seeds demo business data (an admin account plus employees, contracts, RFID cards,
    /// ~13 months of attendance history and leaves) on startup. Reference tables
    /// (roles, departments, positions, leave types, ...) are seeded separately via HasData
    /// in <see cref="LexorDbContext"/>. This runs once and is a no-op when employees already
    /// exist, so it is safe to call on every application start.
    ///
    /// The history is deliberately shaped so absence prediction has a realistic, learnable
    /// signal instead of pure noise:
    ///  - per-employee base absence rate (some people are simply absent more often),
    ///  - weekday effect (Mondays and Fridays are worse),
    ///  - seasonal effect (winter sick season), with sick leaves also biased to winter,
    ///  - annual leaves clustered in summer (vacation season),
    ///  - streaks (being absent yesterday raises the chance of being absent today),
    ///  - a small department effect (production has a higher rate).
    /// This produces two realistic absence peaks: winter (sickness) and summer (vacations).
    /// </summary>
    public static class DataSeeder
    {
        // History window over which attendance and leave history is generated (~13 months,
        // ending close to "today" so the app looks alive on a fresh seed).
        private static readonly DateOnly HistoryStart = new(2025, 7, 1);
        private static readonly DateOnly HistoryEnd = new(2026, 7, 24);

        private const int EmployeeCount = 24;

        // Absence-model coefficients (probabilities are additive per working day).
        private const double MondayFridayEffect = 0.025;
        private const double WinterEffect = 0.035;
        private const double ProductionDeptEffect = 0.02;
        private const double StreakEffect = 0.30; // absent yesterday -> much likelier absent today

        private enum SeasonBias { None, Summer, Winter }

        // Each position belongs to exactly one department, so these (DeptId, PosId) pairs must
        // stay consistent with the reference data seeded in LexorSeed. The salary is a baseline
        // for the position and gets a small random spread per employee.
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
            "Dženana", "Nedim", "Ajla", "Mirza", "Belma", "Edin", "Lamija", "Armin"
        };

        private static readonly string[] LastNames =
        {
            "Hodzic", "Kovacevic", "Begic", "Delic", "Suljic", "Mujic", "Maric", "Hadzic",
            "Softic", "Music", "Halilovic", "Imamovic", "Dedic", "Kadic", "Omerovic", "Sinanovic",
            "Causevic", "Beganovic", "Handzic", "Zukic", "Alic", "Fejzic", "Ramic", "Turkovic"
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

                var email = $"{first.ToLowerInvariant().Replace("ž", "z").Replace("đ", "dj")}.{last.ToLowerInvariant()}@lexor.ba";
                var user = BuildUser(crypto, first, last, email, RandomPhone(rng), "Test123!");
                user.UserRoles.Add(new UserRole { RoleId = 2, DateAssigned = HistoryStart.ToDateTime(TimeOnly.MinValue) });

                // Hired before the history window so every employee has full attendance history.
                var hire = new DateTime(rng.Next(2021, 2025), rng.Next(1, 13), rng.Next(1, 28));
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
                    EndDate = contractTypeId == 1 ? null : hire.AddYears(3),
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

                // Per-employee baseline absence rate (2-7%), nudged up for production so the
                // department carries a small, learnable effect.
                var baseRate = 0.02 + rng.NextDouble() * 0.05
                             + (role.DeptId == 4 ? ProductionDeptEffect : 0.0);

                var leaveRanges = BuildLeaves(employee, admin.Id, baseRate, rng);
                BuildAttendance(employee, card, leaveRanges, baseRate, rng);

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

        // One summer annual-leave block plus sick leaves (mostly in winter). Employees with a
        // higher base absence rate also get more sick leaves, so "who" is a consistent signal.
        // Returns the date ranges so attendance generation can skip the covered days.
        private static List<(DateOnly From, DateOnly To)> BuildLeaves(Employee employee, int adminId,
                                                                      double baseRate, Random rng)
        {
            var ranges = new List<(DateOnly From, DateOnly To)>();

            AddLeave(employee, ranges, adminId, rng, leaveTypeId: 1, reason: "Godišnji odmor",
                     minLen: 5, maxLen: 12, SeasonBias.Summer);

            var sickCount = baseRate > 0.045 ? rng.Next(3, 5) : rng.Next(1, 3);
            for (var i = 0; i < sickCount; i++)
            {
                var bias = rng.NextDouble() < 0.65 ? SeasonBias.Winter : SeasonBias.None;
                AddLeave(employee, ranges, adminId, rng, leaveTypeId: 2, reason: "Bolovanje",
                         minLen: 1, maxLen: 4, bias);
            }

            return ranges;
        }

        private static void AddLeave(Employee employee, List<(DateOnly From, DateOnly To)> ranges, int adminId,
                                     Random rng, int leaveTypeId, string reason, int minLen, int maxLen,
                                     SeasonBias bias)
        {
            var totalDays = HistoryEnd.DayNumber - HistoryStart.DayNumber;
            var length = rng.Next(minLen, maxLen + 1);

            // Rejection-sample a start date that matches the seasonal bias and does not overlap
            // an already generated leave (approved leaves must never overlap).
            DateOnly from;
            var attempts = 0;
            do
            {
                from = HistoryStart.AddDays(rng.Next(0, totalDays - length));
                attempts++;
            }
            while (attempts < 100
                   && (!MatchesBias(from, bias) || Overlaps(ranges, from, from.AddDays(length - 1))));

            if (Overlaps(ranges, from, from.AddDays(length - 1)))
                return; // extremely unlikely; skip rather than seed invalid overlapping leaves

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

        private static bool MatchesBias(DateOnly date, SeasonBias bias) => bias switch
        {
            SeasonBias.Summer => date.Month is 6 or 7 or 8 or 9,
            SeasonBias.Winter => date.Month is 12 or 1 or 2,
            _ => true
        };

        private static bool Overlaps(List<(DateOnly From, DateOnly To)> ranges, DateOnly from, DateOnly to)
            => ranges.Any(r => from <= r.To && to >= r.From);

        // Creates an attendance stamp for every working day in the window, except days covered by a
        // leave or hit by an unexcused absence. The absence probability combines the employee's
        // base rate with weekday, seasonal and streak effects.
        private static void BuildAttendance(Employee employee, RfidCard card,
                                            List<(DateOnly From, DateOnly To)> leaves, double baseRate, Random rng)
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
                if (day.Month is 12 or 1 or 2)
                    probability += WinterEffect; // winter sick season
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
