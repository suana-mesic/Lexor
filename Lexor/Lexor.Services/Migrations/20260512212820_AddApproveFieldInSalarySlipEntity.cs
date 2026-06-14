using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddApproveFieldInSalarySlipEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                table: "SalarySlips");

            migrationBuilder.AddColumn<DateTime>(
                name: "ApprovedAt",
                table: "SalarySlips",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MarkedAsApprovedByAdminId",
                table: "SalarySlips",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "State",
                table: "SalarySlips",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_SalarySlips_MarkedAsApprovedByAdminId",
                table: "SalarySlips",
                column: "MarkedAsApprovedByAdminId");

            migrationBuilder.AddForeignKey(
                name: "FK_SalarySlips_Users_MarkedAsApprovedByAdminId",
                table: "SalarySlips",
                column: "MarkedAsApprovedByAdminId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_SalarySlips_Users_MarkedAsApprovedByAdminId",
                table: "SalarySlips");

            migrationBuilder.DropIndex(
                name: "IX_SalarySlips_MarkedAsApprovedByAdminId",
                table: "SalarySlips");

            migrationBuilder.DropColumn(
                name: "ApprovedAt",
                table: "SalarySlips");

            migrationBuilder.DropColumn(
                name: "MarkedAsApprovedByAdminId",
                table: "SalarySlips");

            migrationBuilder.DropColumn(
                name: "State",
                table: "SalarySlips");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "SalarySlips",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }
    }
}
