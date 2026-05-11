using Lexor.Services.Database;

namespace Lexor.Services.Helpers
{
    internal static class EntityDisplayMessage
    {
        private static readonly Dictionary<Type, string> _notFoundMessage = new()
        {
            { typeof(Attendance), "Prisustvo sa Id-em {0} nije pronađeno." },
            { typeof(Employee), "Zaposlenik sa Id-em {0} nije pronađen." },
            { typeof(RfidCard), "Kartica sa Id-em {0} nije pronađena." },
            { typeof(User), "Korisnik sa Id-em {0} nije pronađen." },
            { typeof(Contract), "Ugovor sa Id-em {0} nije pronađen." },
            { typeof(Department), "Odjel sa Id-em {0} nije pronađen." },
            { typeof(Position), "Pozicija sa Id-em {0} nije pronađena." },
            { typeof(City), "Grad sa Id-em {0} nije pronađen." },
            { typeof(Country), "Država sa Id-em {0} nije pronađena." },
            { typeof(ContractType), "Tip ugovora sa Id-em {0} nije pronađen." },
            { typeof(LeaveType), "Tip odsustva sa Id-em {0} nije pronađen." },
            { typeof(Leave), "Odsustvo sa Id-em {0} nije pronađeno." },
            { typeof(Role), "Uloga sa Id-em {0} nije pronađena." },
            { typeof(PayrollSettings), "Postavke obračuna plate sa Id-em {0} nisu pronađene." },
            { typeof(SalarySlip), "Platna lista sa Id-em {0} nije pronađena." },
            { typeof(LegalDocumentCategory), "Kategorija dokumenta sa Id-em {0} nije pronađena." },
        };

        public static string NotFound(Type entityType, int id)
        {
            return _notFoundMessage.TryGetValue(entityType, out var message)
                ? string.Format(message, id)
                : $"Zapis sa Id-em {id} nije pronađen.";
        }
    }
}
