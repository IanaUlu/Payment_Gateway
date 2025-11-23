using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QiwiGateway.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOsmpCodeToTransaction : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "OsmpCode",
                table: "Transactions",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "OsmpCode",
                table: "Transactions");
        }
    }
}
