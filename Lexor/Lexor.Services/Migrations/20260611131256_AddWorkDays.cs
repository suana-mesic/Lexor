using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkDays : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "WorkDaysDescription",
                table: "PayrollSettings");

            migrationBuilder.AddColumn<int>(
                name: "WorkDaysMask",
                table: "PayrollSettings",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.UpdateData(
                table: "PayrollSettings",
                keyColumn: "Id",
                keyValue: 1,
                column: "WorkDaysMask",
                value: 31);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "WorkDaysMask",
                table: "PayrollSettings");

            migrationBuilder.AddColumn<string>(
                name: "WorkDaysDescription",
                table: "PayrollSettings",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "PayrollSettings",
                keyColumn: "Id",
                keyValue: 1,
                column: "WorkDaysDescription",
                value: "Pon-Pet");
        }
    }
}
