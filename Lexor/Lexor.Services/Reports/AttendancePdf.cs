using Lexor.Model.Responses;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace Lexor.Services.Reports
{
    /// <summary>
    /// The HR side of the reporting module: how much each employee actually worked in a month,
    /// grouped by department. Deliberately separate from the payroll report, which answers a
    /// different question (what everyone was paid) for a different role.
    /// </summary>
    public class AttendancePdf
    {
        static AttendancePdf() => QuestPDF.Settings.License = LicenseType.Community;

        static readonly string[] Months = { "", "Januar", "Februar", "Mart", "April", "Maj",
            "Juni", "Juli", "August", "Septembar", "Oktobar", "Novembar", "Decembar" };

        // Minutes past midnight back to a readable clock time (510 -> "08:30").
        static string Clock(int? minutes) =>
            minutes.HasValue ? $"{minutes.Value / 60:D2}:{minutes.Value % 60:D2}" : "—";

        static string Hours(decimal v) => $"{v:N2}";

        public static byte[] MonthlyReport(AttendanceReportResponse report)
        {
            return Document.Create(doc => doc.Page(p =>
            {
                p.Margin(30);
                p.Header().Column(c =>
                {
                    c.Item().Text($"Izvještaj evidencije radnog vremena — {Months[report.Month]} {report.Year}")
                        .FontSize(18).Bold();
                    c.Item().PaddingTop(4)
                        .Text($"Radnih dana u mjesecu: {report.WorkingDays}")
                        .FontSize(10).FontColor(Colors.Grey.Darken2);
                });

                p.Content().PaddingVertical(15).Table(t =>
                {
                    t.ColumnsDefinition(cd =>
                    {
                        cd.RelativeColumn(3); cd.RelativeColumn(2); cd.RelativeColumn(2);
                        cd.RelativeColumn(2); cd.RelativeColumn(2); cd.RelativeColumn(2);
                        cd.RelativeColumn(2);
                    });
                    t.Header(h =>
                    {
                        h.Cell().Text("Uposlenik").Bold();
                        h.Cell().AlignRight().Text("Prisutan").Bold();
                        h.Cell().AlignRight().Text("Odsustvo").Bold();
                        h.Cell().AlignRight().Text("Bez evid.").Bold();
                        h.Cell().AlignRight().Text("Ukupno h").Bold();
                        h.Cell().AlignRight().Text("Prosj. h").Bold();
                        h.Cell().AlignRight().Text("Prosj. dolazak").Bold();
                    });

                    var byDepartment = report.Rows
                        .GroupBy(r => r.DepartmentName)
                        .OrderBy(g => g.Key)
                        .ToList();

                    foreach (var dept in byDepartment)
                    {
                        t.Cell().ColumnSpan(7).PaddingTop(8)
                            .Text(dept.Key).Bold().FontColor(Colors.Grey.Darken2);

                        foreach (var r in dept)
                        {
                            t.Cell().PaddingLeft(8).Text(r.FullName);
                            t.Cell().AlignRight().Text($"{r.PresentDays}");
                            t.Cell().AlignRight().Text($"{r.LeaveDays}");
                            // Unexplained gaps are what HR reads this report for, so they are
                            // the one figure that stands out rather than blending in.
                            t.Cell().AlignRight().Text($"{r.MissingDays}")
                                .FontColor(r.MissingDays > 0 ? Colors.Red.Darken1 : Colors.Black);
                            t.Cell().AlignRight().Text(Hours(r.TotalHours));
                            t.Cell().AlignRight().Text(Hours(r.AverageHours));
                            t.Cell().AlignRight().Text(Clock(r.AverageArrivalMinutes));
                        }

                        t.Cell().PaddingLeft(8).PaddingTop(2).Text($"Ukupno — {dept.Key}").Italic();
                        t.Cell().PaddingTop(2).AlignRight().Text($"{dept.Sum(x => x.PresentDays)}").Italic();
                        t.Cell().PaddingTop(2).AlignRight().Text($"{dept.Sum(x => x.LeaveDays)}").Italic();
                        t.Cell().PaddingTop(2).AlignRight().Text($"{dept.Sum(x => x.MissingDays)}").Italic();
                        t.Cell().PaddingTop(2).AlignRight().Text(Hours(dept.Sum(x => x.TotalHours))).Italic();
                        t.Cell().ColumnSpan(2);
                    }

                    t.Cell().PaddingTop(6).Text("UKUPNO").Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text($"{report.Rows.Sum(x => x.PresentDays)}").Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text($"{report.Rows.Sum(x => x.LeaveDays)}").Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text($"{report.Rows.Sum(x => x.MissingDays)}").Bold();
                    t.Cell().PaddingTop(6).AlignRight().Text(Hours(report.Rows.Sum(x => x.TotalHours))).Bold();
                    t.Cell().ColumnSpan(2);
                });

                p.Footer().Row(r =>
                {
                    r.RelativeItem().Text($"Ukupno uposlenika: {report.Rows.Count}").FontSize(9);
                    r.RelativeItem().AlignRight()
                        .Text($"Generisano: {DateTime.UtcNow:dd.MM.yyyy. HH:mm}").FontSize(9);
                });
            })).GeneratePdf();
        }
    }
}
