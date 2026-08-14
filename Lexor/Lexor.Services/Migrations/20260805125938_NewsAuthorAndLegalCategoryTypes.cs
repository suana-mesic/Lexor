using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class NewsAuthorAndLegalCategoryTypes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "PublishedByUserId",
                table: "News",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "LegalDocumentCategories",
                keyColumn: "Id",
                keyValue: 1,
                column: "Name",
                value: "Zakon");

            migrationBuilder.UpdateData(
                table: "LegalDocumentCategories",
                keyColumn: "Id",
                keyValue: 2,
                column: "Name",
                value: "Pravilnik");

            migrationBuilder.UpdateData(
                table: "LegalDocumentCategories",
                keyColumn: "Id",
                keyValue: 3,
                column: "Name",
                value: "Dopuna/izmjena");

            migrationBuilder.CreateIndex(
                name: "IX_News_PublishedByUserId",
                table: "News",
                column: "PublishedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_News_Users_PublishedByUserId",
                table: "News",
                column: "PublishedByUserId",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_News_Users_PublishedByUserId",
                table: "News");

            migrationBuilder.DropIndex(
                name: "IX_News_PublishedByUserId",
                table: "News");

            migrationBuilder.DropColumn(
                name: "PublishedByUserId",
                table: "News");

            migrationBuilder.UpdateData(
                table: "LegalDocumentCategories",
                keyColumn: "Id",
                keyValue: 1,
                column: "Name",
                value: "Zakon o radu");

            migrationBuilder.UpdateData(
                table: "LegalDocumentCategories",
                keyColumn: "Id",
                keyValue: 2,
                column: "Name",
                value: "Zakon o zaštiti na radu");

            migrationBuilder.UpdateData(
                table: "LegalDocumentCategories",
                keyColumn: "Id",
                keyValue: 3,
                column: "Name",
                value: "Pravilnik o radu");
        }
    }
}
