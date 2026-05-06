using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class ModifyContractType_EndDateRequired_3 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedAtByUserId",
                table: "Employees",
                newName: "UpdatedByUserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedByUserId",
                table: "Employees",
                newName: "UpdatedAtByUserId");
        }
    }
}
