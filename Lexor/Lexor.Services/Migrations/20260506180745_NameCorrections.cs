using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class NameCorrections : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedAtByUserId",
                table: "Contracts",
                newName: "UpdatedByUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedByUserId",
                table: "Contracts",
                newName: "UpdatedAtByUserId");
        }
    }
}
