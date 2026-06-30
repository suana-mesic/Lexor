using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkStartTimeColumn_PayrollSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<TimeOnly>(
                name: "WorkStartTime",
                table: "PayrollSettings",
                type: "time",
                nullable: false,
                defaultValue: new TimeOnly(9, 0, 0));

            migrationBuilder.UpdateData(
                table: "PayrollSettings",
                keyColumn: "Id",
                keyValue: 1,
                column: "WorkStartTime",
                value: new TimeOnly(9, 0, 0));
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "WorkStartTime",
                table: "PayrollSettings");
        }
    }
}
