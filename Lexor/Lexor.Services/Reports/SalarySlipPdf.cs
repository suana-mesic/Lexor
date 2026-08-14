using Lexor.Model.Enums;
using Lexor.Model.Responses;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace Lexor.Services.Reports
{
    public class SalarySlipPdf
    {
        static SalarySlipPdf() => QuestPDF.Settings.License = LicenseType.Community;
        static string Km(decimal v) => $"{v:N2} KM";

        // Amount the employee earned from overtime this period (0 if there were no overtime items).
        static decimal Overtime(SalarySlipResponse s) =>
            s.Items?.Where(i => i.ItemType == SalarySlipItemType.Overtime).Sum(i => i.Amount) ?? 0m;
        static readonly string[] Months = { "", "Januar", "Februar", "Mart", "April", "Maj",
            "Juni", "Juli", "August", "Septembar", "Oktobar", "Novembar", "Decembar" };

        public static byte[] SingleSlip(SalarySlipResponse s)
        {
            var name = $"{s.Employee.User.FirstName} {s.Employee.User.LastName}";
            return Document.Create(doc => doc.Page(p =>
            {
                p.Margin(30);
                p.Header().Column(c =>
                {
                    c.Item().Text("Platna lista").FontSize(18).Bold();
                    c.Item().Text($"{name} — {Months[s.Month]} {s.Year}").FontColor(Colors.Grey.Darken1);
                });
                p.Content().PaddingVertical(15).Table(t =>
                {
                    t.ColumnsDefinition(cd => { cd.RelativeColumn(3); cd.RelativeColumn(1); cd.RelativeColumn(1); });
                    t.Header(h =>
                    {
                        h.Cell().Text("Stavka").Bold();
                        h.Cell().AlignRight().Text("Stopa").Bold();
                        h.Cell().AlignRight().Text("Iznos").Bold();
                    });
                    foreach (var i in s.Items ?? new())
                    {
                        t.Cell().Text(i.Name);
                        t.Cell().AlignRight().Text(i.Rate.HasValue ? $"{i.Rate}%" : "—");
                        t.Cell().AlignRight().Text(Km(i.Amount));
                    }
                    t.Cell().PaddingTop(6).Text("Neto plata").Bold();
                    t.Cell();
                    t.Cell().PaddingTop(6).AlignRight().Text(Km(s.NetSalary)).Bold();
                });
                p.Footer().AlignRight().Text(x =>
                {
                    x.Span("Generisano: ");
                    x.Span($"{s.GeneratedAt:dd.MM.yyyy}");
                });
            })).GeneratePdf();
        }

        public static byte[] MonthlyReport(int year, int month, List<SalarySlipResponse> slips)
        {
            return Document.Create(doc => doc.Page(p =>
            {
                p.Margin(30);
                p.Header().Text($"Izvještaj plata — {Months[month]} {year}").FontSize(18).Bold();
                p.Content().PaddingVertical(15).Table(t =>
                {
                    t.ColumnsDefinition(cd =>
                    {
                        cd.RelativeColumn(3); cd.RelativeColumn(2); cd.RelativeColumn(2);
                        cd.RelativeColumn(2); cd.RelativeColumn(2); cd.RelativeColumn(2);
                    });
                    t.Header(h =>
                    {
                        h.Cell().Text("Uposlenik").Bold();
                        h.Cell().AlignRight().Text("Bruto").Bold();
                        h.Cell().AlignRight().Text("Prekovremeni").Bold();
                        h.Cell().AlignRight().Text("Doprinosi").Bold();
                        h.Cell().AlignRight().Text("Porez").Bold();
                        h.Cell().AlignRight().Text("Neto").Bold();
                    });
                    foreach (var s in slips)
                    {
                        t.Cell().Text($"{s.Employee.User.FirstName} {s.Employee.User.LastName}");
                        t.Cell().AlignRight().Text(Km(s.BrutoSalary));
                        t.Cell().AlignRight().Text(Km(Overtime(s)));
                        t.Cell().AlignRight().Text(Km(s.TotalContributions));
                        t.Cell().AlignRight().Text(Km(s.Tax));
                        t.Cell().AlignRight().Text(Km(s.NetSalary));
                    }
                    t.Cell().PaddingTop(6).Text("UKUPNO").Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text(Km(slips.Sum(x => x.BrutoSalary))).Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text(Km(slips.Sum(Overtime))).Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text(Km(slips.Sum(x => x.TotalContributions))).Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text(Km(slips.Sum(x => x.Tax))).Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text(Km(slips.Sum(x => x.NetSalary))).Bold();
                });
                p.Footer().AlignRight().Text($"Ukupno zaposlenika: {slips.Count}");
            })).GeneratePdf();
        }
    }
}
