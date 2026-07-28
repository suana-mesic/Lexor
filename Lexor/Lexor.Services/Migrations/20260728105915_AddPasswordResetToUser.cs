using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddPasswordResetToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PasswordResetCodeHash",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PasswordResetCodeSalt",
                table: "Users",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PasswordResetExpiresAt",
                table: "Users",
                type: "datetime2",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PasswordResetCodeHash",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PasswordResetCodeSalt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "PasswordResetExpiresAt",
                table: "Users");
        }
    }
}
