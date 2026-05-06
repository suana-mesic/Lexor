using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class EmployeeAndUserModificationsUpdatedAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ModifiedByUserId",
                table: "Employees",
                newName: "UpdatedAtByUserId");

            migrationBuilder.RenameColumn(
                name: "ModifiedAt",
                table: "Employees",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "ModifiedByUserId",
                table: "Contracts",
                newName: "UpdatedAtByUserId");

            migrationBuilder.RenameColumn(
                name: "ModifiedAt",
                table: "Contracts",
                newName: "UpdatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedAtByUserId",
                table: "Employees",
                newName: "ModifiedByUserId");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "Employees",
                newName: "ModifiedAt");

            migrationBuilder.RenameColumn(
                name: "UpdatedAtByUserId",
                table: "Contracts",
                newName: "ModifiedByUserId");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "Contracts",
                newName: "ModifiedAt");
        }
    }
}
