using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Lexor.Services.Migrations
{
    /// <inheritdoc />
    public partial class AddNewsThumbnail : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ThumbnailBase64",
                table: "News",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ThumbnailBase64",
                table: "News");
        }
    }
}
