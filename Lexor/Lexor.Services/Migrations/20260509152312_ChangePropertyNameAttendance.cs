using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class ChangePropertyNameAttendance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Attendances_Users_CorrectedByAdminId",
                table: "Attendances");

            migrationBuilder.DropIndex(
                name: "IX_Attendances_CorrectedByAdminId",
                table: "Attendances");

            migrationBuilder.AddColumn<int>(
                name: "UpdatedByUserId",
                table: "Attendances",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Attendances_UpdatedByUserId",
                table: "Attendances",
                column: "UpdatedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Attendances_Users_UpdatedByUserId",
                table: "Attendances",
                column: "UpdatedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Attendances_Users_UpdatedByUserId",
                table: "Attendances");

            migrationBuilder.DropIndex(
                name: "IX_Attendances_UpdatedByUserId",
                table: "Attendances");

            migrationBuilder.DropColumn(
                name: "UpdatedByUserId",
                table: "Attendances");

            migrationBuilder.CreateIndex(
                name: "IX_Attendances_CorrectedByAdminId",
                table: "Attendances",
                column: "CorrectedByAdminId");

            migrationBuilder.AddForeignKey(
                name: "FK_Attendances_Users_CorrectedByAdminId",
                table: "Attendances",
                column: "CorrectedByAdminId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
