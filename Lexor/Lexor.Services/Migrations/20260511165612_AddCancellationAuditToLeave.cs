using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddCancellationAuditToLeave : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "Leaves",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancelledByUserId",
                table: "Leaves",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Leaves_CancelledByUserId",
                table: "Leaves",
                column: "CancelledByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Leaves_Users_CancelledByUserId",
                table: "Leaves",
                column: "CancelledByUserId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Leaves_Users_CancelledByUserId",
                table: "Leaves");

            migrationBuilder.DropIndex(
                name: "IX_Leaves_CancelledByUserId",
                table: "Leaves");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "Leaves");

            migrationBuilder.DropColumn(
                name: "CancelledByUserId",
                table: "Leaves");
        }
    }
}
