using Lexor.Services.Helpers;
using Lexor.Services.StateMachine.LeaveStateMachine;
using Microsoft.EntityFrameworkCore;

namespace Lexor.Services.Database
{
    /// <summary>
    /// Seeds demo business data (role accounts plus 30 employees, contracts, RFID cards, about
    /// 19 months of attendance history and roughly a thousand leave records) on startup. Reference
    /// tables (roles, departments, positions, leave types, ...) are seeded separately via HasData
    /// in <see cref="LexorDbContext"/>. This runs once and is a no-op when employees already exist,
    /// so it is safe to call on every application start.
    ///
    /// The attendance history feeds the fraud-detection classifier: about 10,000 records of which
    /// exactly <see cref="FraudCount"/> are marked fraudulent (see <see cref="InjectFraud"/>).
    /// Fraud is injected as manipulated arrival/departure times and repeated departure edits, kept
    /// at or below contracted hours so payroll stays correct, and mixed with legitimate look-alikes
    /// (overtime, flex arrivals, approved short days, single corrections) so it cannot be separated
    /// by a single threshold.
    /// </summary>
    public static class DataSeeder
    {
        // ~19-month history window ending yesterday. Anchored to the current date rather than a
        // fixed one so the current month is never empty (the mobile calendar opens on it) and so
        // payroll, which is seeded relative to today, never covers a month without attendance.
        private static readonly DateOnly HistoryEnd =
            DateOnly.FromDateTime(DateTime.UtcNow).AddDays(-1);

        // Start of the month 18 months back, so the window length — and with it the number of
        // attendance records the fraud classifier trains on — stays stable whenever it is seeded.
        private static readonly DateOnly HistoryStart =
            new DateOnly(HistoryEnd.Year, HistoryEnd.Month, 1).AddMonths(-18);

        private const int EmployeeCount = 30;

        // Number of attendance records marked as fraudulent (labelled ground truth for training).
        private const int FraudCount = 300;

        // Mon-Fri, matching the seeded payroll settings (WorkDaysMask = 31). Attendance is
        // stamped on these days and leaves must begin and end on one of them.
        private static bool IsWorkDay(DateOnly day) =>
            day.DayOfWeek != DayOfWeek.Saturday && day.DayOfWeek != DayOfWeek.Sunday;

        // Monthly probabilities for the random leave noise, so the leave history stays realistic
        // and varied (annual/sick/paid/unpaid leaves spread across the window).
        private const double RandomSickChancePerMonth = 0.10;
        private const double OtherLeaveChancePerMonth = 0.40;
        private const double MiniVacationChancePerMonth = 0.12;

        // Requests that never became time off, so the request history shows every state.
        private const double RejectedRequestChancePerMonth = 0.06;
        private const double CancelledRequestChancePerMonth = 0.05;

        // Realistic HR texts for rejected and withdrawn requests.
        private static readonly string[] RejectionReasons =
        {
            "Previše uposlenika iz odjela je odsutno u traženom periodu.",
            "Zahtjev se preklapa s planiranim projektnim rokom.",
            "Nedovoljno preostalih dana godišnjeg odmora.",
            "U traženom periodu je planirano godišnje inventurisanje.",
        };

        private static readonly string[] CancellationReasons =
        {
            "Promjena privatnih planova.",
            "Odsustvo mi više nije potrebno.",
            "Prebacit ću odsustvo za kasniji termin.",
        };

        // Overtime model: employees always work at least their contracted hours; on some days
        // they stay 1-3 hours longer (deliberate overtime blocks, never a stray few minutes).
        private const double OvertimeChancePerDay = 0.15;

        // Each position belongs to exactly one department (must match LexorSeed reference data).
        private static readonly (int DeptId, int PosId, decimal BaseSalary)[] Roles =
        {
            (1, 1, 3200m), // HR manager
            (1, 2, 1900m), // Recruitment specialist
            (2, 3, 2600m), // Programmer
            (2, 4, 2800m), // DevOps engineer
            (3, 5, 2000m), // Sales representative
            (4, 6, 2900m), // Production manager
            (5, 7, 2400m), // Accountant
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

        // Real reader UIDs for the first employees (for scanning demos); the rest get a random UID.
        private static readonly string[] SeededRfidUids =
        {
            "F38C1422", "13577C21", "C3C99B21", "53531822", "03EC1D22",
            "43747722", "73D11F22", "13AD8421", "F32B2E22"
        };

        /// <summary>
        /// Fills in the list thumbnail for users that already have a profile picture but no
        /// thumbnail yet — databases created before the thumbnail column existed. Matches no
        /// rows once it has run, so it costs a single indexed count on every later startup.
        /// </summary>
        public static async Task BackfillProfileThumbnailsAsync(LexorDbContext db)
        {
            var pending = await db.Users
                .Where(u => u.ProfileImageBase64 != null && u.ProfileThumbnailBase64 == null)
                .ToListAsync();

            if (pending.Count == 0)
                return;

            foreach (var user in pending)
                user.ProfileThumbnailBase64 = ImageThumbnail.Create(user.ProfileImageBase64);

            await db.SaveChangesAsync();
        }

        public static async Task SeedAsync(LexorDbContext db, ICryptoService crypto)
        {
            // Business data is generated only for a fresh database; reference data lives in HasData.
            if (await db.Employees.AnyAsync())
                return;

            // Wrap the whole seed in one transaction: the role users are saved early (their Ids are
            // needed as CreatedByUserId), so without this an interrupted/failed run would leave those
            // users behind while the guard above still sees no employees — the next run would then try
            // to insert the same users again and fail on the unique email index.
            await using var transaction = await db.Database.BeginTransactionAsync();

            // Deterministic randomness so a fresh seed always produces the same data set.
            var rng = new Random(20260101);

            // ----- Fixed role accounts: one clean login per role (password Test123!) -----
            var hrManager  = BuildRoleUser(crypto, "HR", "Menadžer", "hr.menadzer@lexor.ba", "hr.menadzer", "061100100", roleId: 1);
            var admin      = BuildRoleUser(crypto, "Admin", "Admin", "admin@lexor.ba", "admin", "061100200", roleId: 4);
            var accounting = BuildRoleUser(crypto, "Računovodstvo", "Računovodstvo", "racunovodstvo@lexor.ba", "racunovodstvo", "061100300", roleId: 3);
            // Second accounting account so separation of duties can be shown: one approves, the other pays.
            var accounting2 = BuildRoleUser(crypto, "Računovodstvo", "Kontrola", "racunovodstvo2@lexor.ba", "racunovodstvo2", "061100400", roleId: 3);
            db.Users.AddRange(hrManager, admin, accounting, accounting2);
            await db.SaveChangesAsync(); // persist so their Ids can be used as CreatedByUserId

            var creatorId = hrManager.Id; // HR manager is the audit "creator" of employee records

            // Builds one fully-featured demo employee (contract, RFID, three-year attendance and
            // leave history with per-employee seasonality) for the given identity and index.
            Employee BuildEmployee(int i, string first, string last, string email,
                                   string username, string? avatarBase64)
            {
                var role = Roles[i % Roles.Length];

                var user = BuildUser(crypto, first, last, email, RandomPhone(rng), "Test123!");
                user.Username = username;
                if (avatarBase64 != null)
                {
                    user.ProfileImageBase64 = avatarBase64;
                    user.ProfileThumbnailBase64 = ImageThumbnail.Create(avatarBase64);
                }
                user.UserRoles.Add(new UserRole { RoleId = 2, DateAssigned = HistoryStart.ToDateTime(TimeOnly.MinValue) });

                // Personal seasonality profile. The formulas spread months evenly across
                // employees and can never make both peaks land on the same month.
                var vacationMonth = 1 + (i * 5) % 12;
                var sickPeakMonth = 1 + (i * 7 + 3) % 12;
                // Kept purely to preserve the deterministic random sequence that the rest
                // of the seed depends on; the unexcused-absence model it fed is gone.
                _ = rng.NextDouble();

                // Hired before the history window so every employee has full 3-year history.
                var hire = new DateTime(rng.Next(2019, 2023), rng.Next(1, 13), rng.Next(1, 28));
                var contractTypeId = i % 5 == 0 ? 2 : 1; // every fifth employee is on a fixed-term contract
                var workHoursPerDay = first == "Amina" && last == "Hodžić" ? 9 : 8;

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
                    CreatedByUserId = creatorId
                };

                employee.Contracts.Add(new Contract
                {
                    ContractTypeId = contractTypeId,
                    StartDate = hire,
                    // Fixed-term contracts end after the seeded history so payroll stays simple.
                    EndDate = contractTypeId == 1 ? null : new DateTime(2027, 12, 31),
                    BrutoSalary = role.BaseSalary + rng.Next(-2, 4) * 100m,
                    WorkHoursPerDay = workHoursPerDay,
                    CreatedAt = hire,
                    CreatedByUserId = creatorId
                });

                // First employees get real reader UIDs; the rest get a random 8-hex UID.
                var uid = i < SeededRfidUids.Length
                    ? SeededRfidUids[i]
                    : $"{rng.Next(0x10000):X4}{rng.Next(0x10000):X4}";
                var card = new RfidCard
                {
                    Uid = uid,
                    AssignedAt = hire,
                    IsActive = true
                };
                employee.RfidCards.Add(card);

                // Rejected/cancelled requests draw from a SEPARATE deterministic stream, so adding
                // them never shifts the shared rng sequence behind attendance and fraud injection.
                var requestNoiseRng = new Random(7919 * (i + 1));
                var leaveRanges = BuildLeaves(employee, creatorId, vacationMonth, sickPeakMonth, rng, requestNoiseRng);
                BuildAttendance(employee, card, leaveRanges, workHoursPerDay, rng);

                return employee;
            }

            var employees = new List<Employee>();
            for (var i = 0; i < EmployeeCount; i++)
            {
                var first = FirstNames[i];
                var last = LastNames[i];
                var employee = BuildEmployee(
                    i, first, last,
                    $"{Asciify(first)}.{Asciify(last)}@lexor.ba",
                    $"{Asciify(first)}.{Asciify(last)}",
                    SeedAvatars.Base64[i]);
                employees.Add(employee);
                db.Employees.Add(employee);
            }

            // Mark exactly FraudCount attendance records as fraudulent, spread across all employees
            // and the whole timeline (so the chronological train/test split has fraud in both halves).
            InjectFraud(employees, rng);

            // ----- Company announcements (news) -----
            db.News.AddRange(
                new News
                {
                    Title = "Kolektivni godišnji odmor",
                    Content = "Obavještavamo sve uposlenike da je kolektivni godišnji odmor planiran za period od 1. do 15. augusta. Molimo da svoje obaveze uskladite na vrijeme.",
                    ImageBase64 = SeedNews.Images[0],
                    PublishedAt = new DateTime(2026, 7, 20, 9, 0, 0, DateTimeKind.Utc),
                    PublishedByUserId = creatorId
                },
                new News
                {
                    Title = "Nova politika rada od kuće",
                    Content = "Od 1. septembra uvodimo mogućnost rada od kuće do dva dana sedmično, uz prethodni dogovor sa nadređenim. Detalji su dostupni u HR odjelu.",
                    ImageBase64 = SeedNews.Images[1],
                    PublishedAt = new DateTime(2026, 7, 15, 9, 0, 0, DateTimeKind.Utc),
                    PublishedByUserId = creatorId
                },
                new News
                {
                    Title = "Raspored isplate plata",
                    Content = "Isplata plata za tekući mjesec bit će izvršena 5. u narednom mjesecu. Za sva pitanja obratite se finansijskom odjelu.",
                    ImageBase64 = SeedNews.Images[2],
                    PublishedAt = new DateTime(2026, 7, 10, 9, 0, 0, DateTimeKind.Utc),
                    PublishedByUserId = creatorId
                });

            await db.SaveChangesAsync();
            await transaction.CommitAsync();
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

        // Builds a fixed login account with a username and a single role (password Test123!).
        private static User BuildRoleUser(ICryptoService crypto, string first, string last,
                                          string email, string username, string phone, int roleId)
        {
            var user = BuildUser(crypto, first, last, email, phone, "Test123!");
            user.Username = username;
            user.UserRoles.Add(new UserRole { RoleId = roleId, DateAssigned = DateTime.UtcNow });
            return user;
        }

        // Walks month by month through the history window and generates this employee's leaves:
        // an annual-leave block in their personal vacation month, recurring multi-day sick
        // blocks in their personal sick-peak month, plus random short leaves as noise. A few
        // rejected/cancelled requests (from requestNoiseRng) complete the request history.
        private static List<(DateOnly From, DateOnly To)> BuildLeaves(Employee employee, int adminId,
                                                                      int vacationMonth, int sickPeakMonth,
                                                                      Random rng, Random requestNoiseRng)
        {
            var ranges = new List<(DateOnly From, DateOnly To)>();

            var month = new DateOnly(HistoryStart.Year, HistoryStart.Month, 1);
            while (month <= HistoryEnd)
            {
                // Requests that never became time off (rejected by HR / withdrawn by the employee).
                if (requestNoiseRng.NextDouble() < RejectedRequestChancePerMonth)
                    AddNonTakenLeave(employee, adminId, requestNoiseRng, month, rejected: true);
                if (requestNoiseRng.NextDouble() < CancelledRequestChancePerMonth)
                    AddNonTakenLeave(employee, adminId, requestNoiseRng, month, rejected: false);

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
                var candidateTo = from.AddDays(length - 1);
                placed = !Overlaps(ranges, from, candidateTo)
                         && from >= HistoryStart
                         && candidateTo <= HistoryEnd
                         // Nobody books time off starting or ending on a weekend — it would show
                         // as a leave day on a day that is not a working day anyway.
                         && IsWorkDay(from)
                         && IsWorkDay(candidateTo);
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

        // Adds a request that never resulted in time off: rejected by HR (with a reason) or
        // cancelled by the employee. Deliberately NOT added to `ranges` — the employee still
        // worked those days, so attendance stamps must not be suppressed by these requests.
        private static void AddNonTakenLeave(Employee employee, int adminId, Random rng,
                                             DateOnly month, bool rejected)
        {
            var length = rng.Next(1, 5);
            var daysInMonth = DateTime.DaysInMonth(month.Year, month.Month);
            var from = new DateOnly(month.Year, month.Month, rng.Next(1, Math.Max(2, daysInMonth - length)));
            var to = from.AddDays(length - 1);
            if (from < HistoryStart || to > HistoryEnd)
                return;

            // Same rule as for approved leaves: a request never starts or ends on a weekend.
            if (!IsWorkDay(from) || !IsWorkDay(to))
                return;

            // The request was submitted well before its start date; the decision followed shortly.
            var created = from.ToDateTime(TimeOnly.MinValue).AddDays(-rng.Next(5, 15));
            var decidedAt = created.AddDays(rng.Next(1, 4));

            var annual = rng.NextDouble() < 0.5;
            var leave = new Leave
            {
                LeaveTypeId = annual ? 1 : 3,
                DateFrom = from,
                DateTo = to,
                NumberOfDays = length,
                Reason = annual ? "Godišnji odmor" : "Plaćeno odsustvo",
                CreatedAt = created,
            };

            if (rejected)
            {
                leave.State = nameof(RejectedLeaveState);
                leave.RejectedByAdminId = adminId;
                leave.RejectedAt = decidedAt;
                leave.RejectionReason = RejectionReasons[rng.Next(RejectionReasons.Length)];
            }
            else
            {
                leave.State = nameof(CancelledLeaveState);
                leave.CancelledByUser = employee.User; // the employee withdrew their own request
                leave.CancelledAt = decidedAt;
                leave.CancellationReason = CancellationReasons[rng.Next(CancellationReasons.Length)];
            }

            employee.Leaves.Add(leave);
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

        // Creates an attendance stamp for every working day in the window that is not covered by
        // an approved leave. Every other working day gets a record, so a gap in the calendar
        // always means an actual leave rather than missing demo data.
        private static void BuildAttendance(Employee employee, RfidCard card,
                                            List<(DateOnly From, DateOnly To)> leaves,
                                            int workHoursPerDay, Random rng)
        {
            for (var day = HistoryStart; day <= HistoryEnd; day = day.AddDays(1))
            {
                if (!IsWorkDay(day))
                    continue;

                if (leaves.Any(r => day >= r.From && day <= r.To))
                    continue;

                // Normal attendance: arrives 08:00-08:15 and works at least the contracted hours;
                // on ~15% of days a real overtime block (45 min - 3 h). A minority of days are
                // legitimate exceptions that deliberately RESEMBLE fraud without being fraud (flex
                // late arrival, approved early departure, a single correction), so no single
                // threshold cleanly separates fraud from normal work.
                var enter = day.ToDateTime(new TimeOnly(8, rng.Next(0, 16)));
                var shiftEnd = day.ToDateTime(new TimeOnly(8, 0)).AddHours(workHoursPerDay);
                DateTime left;

                var roll = rng.NextDouble();
                if (roll < 0.03)
                {
                    // Approved flexible start: arrives 08:30-09:00 (looks like a late-arrival fraud).
                    enter = day.ToDateTime(new TimeOnly(8, 30)).AddMinutes(rng.Next(0, 31));
                    left = enter.AddMinutes(workHoursPerDay * 60 - rng.Next(0, 41));
                }
                else if (roll < 0.09)
                {
                    // Approved short day: leaves 20-70 min early (looks like an early-departure fraud).
                    left = shiftEnd.AddMinutes(-rng.Next(20, 71));
                }
                else
                {
                    var extraMinutes = rng.Next(0, 21); // 0-20 min: ordinary variance, below overtime grace
                    if (rng.NextDouble() < OvertimeChancePerDay)
                        extraMinutes = rng.Next(9, 37) * 5; // 45-180 min real overtime block
                    left = enter.AddMinutes(workHoursPerDay * 60 + extraMinutes);
                }

                // A few normal records carry one (or rarely two) legitimate corrections, so the
                // departure-edit count on its own is not a giveaway either.
                var editCount = rng.NextDouble() < 0.06 ? 1
                              : rng.NextDouble() < 0.02 ? 2
                              : 0;

                employee.Attendances.Add(new Attendance
                {
                    RfidCard = card,
                    Date = day,
                    DateTimeEntered = enter,
                    DateTimeLeft = left,
                    DepartureEditCount = editCount,
                    IsFraud = false,
                    WorkedHours = Math.Round((decimal)(left - enter).TotalHours, 2)
                });
            }
        }

        // Marks FraudCount attendance records as fraudulent by manipulating their times / edit-count
        // in line with the risk indicators, while keeping worked hours at or below the contracted
        // amount so payroll (fixed bruto + overtime only) stays correct. The records are chosen at
        // random across the whole timeline, so the later chronological test split still contains fraud.
        private static void InjectFraud(List<Employee> employees, Random rng)
        {
            var records = employees
                .SelectMany(e => e.Attendances.Select(a => (Att: a, Hours: e.Contracts.First().WorkHoursPerDay)))
                .Where(x => x.Att.DateTimeEntered.HasValue && x.Att.DateTimeLeft.HasValue)
                .ToList();
            if (records.Count == 0)
                return;

            var minDate = records.Min(x => x.Att.Date);
            var maxDate = records.Max(x => x.Att.Date);

            foreach (var (att, hours) in records.OrderBy(_ => rng.Next()).Take(FraudCount))
                ApplyFraud(att, hours, minDate, maxDate, rng);
        }

        // Turns one record into a fraudulent one following a random archetype (late arrival, early
        // departure, repeatedly edited departure, or a combination). Fraud in the last quarter of the
        // timeline is made subtler so it overlaps more with normal behaviour — this is what makes the
        // chronological test F1 land below the train F1.
        private static void ApplyFraud(Attendance att, int workHoursPerDay, DateOnly minDate, DateOnly maxDate, Random rng)
        {
            var span = Math.Max(1, maxDate.DayNumber - minDate.DayNumber);
            var t = (double)(att.Date.DayNumber - minDate.DayNumber) / span; // 0..1 along the timeline

            var shiftStart = att.Date.ToDateTime(new TimeOnly(8, 0));
            var shiftEnd = shiftStart.AddHours(workHoursPerDay);

            // Start from a normal-looking day, then stack "red flags" on top.
            var enter = shiftStart.AddMinutes(rng.Next(0, 11));
            var left = shiftEnd.AddMinutes(rng.Next(-5, 6));
            var editCount = 0;

            // A subtle minority (more common in the later period) carries only ONE mild flag, so it
            // looks like ordinary behaviour and the model misses some of it -> F1 stays below 1.0
            // and the later chronological test split is harder than train.
            var subtle = rng.NextDouble() < (t > 0.75 ? 0.30 : 0.12);

            if (subtle)
            {
                switch (rng.Next(3))
                {
                    case 0: enter = shiftStart.AddMinutes(rng.Next(30, 46)); break; // mildly late
                    case 1: left = shiftEnd.AddMinutes(-rng.Next(30, 46)); break;   // mildly early
                    default: editCount = 2; break;                                  // just two edits
                }
            }
            else
            {
                // Clear fraud = a COMBINATION of red flags at once: late arrival AND early departure
                // AND several departure edits. Legitimate exceptions only ever have ONE of these, so
                // the model learns to flag the combination, not any single indicator.
                enter = shiftStart.AddMinutes(rng.Next(45, 100)); // clearly late
                left = shiftEnd.AddMinutes(-rng.Next(45, 100));   // clearly early
                editCount = rng.Next(2, 6);                       // repeatedly edited
            }

            // Never let manipulated hours exceed the contract, so no fraudulent overtime is ever paid.
            var cap = enter.AddHours(workHoursPerDay);
            if (left > cap) left = cap;
            if (left <= enter) left = enter.AddHours(1);

            att.DateTimeEntered = enter;
            att.DateTimeLeft = left;
            att.DepartureEditCount = editCount;
            att.IsFraud = true;
            att.WorkedHours = Math.Round((decimal)(left - enter).TotalHours, 2);
        }

        private static string RandomPhone(Random rng) => $"06{rng.Next(0, 4)}{rng.Next(100000, 999999)}";
    }
}
