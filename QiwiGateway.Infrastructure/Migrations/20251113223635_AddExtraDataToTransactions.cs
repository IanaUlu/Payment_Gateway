using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QiwiGateway.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddExtraDataToTransactions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ExtraData",
                table: "Transactions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PayType",
                table: "Transactions",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ExtraData",
                table: "Transactions");

            migrationBuilder.DropColumn(
                name: "PayType",
                table: "Transactions");
        }
    }
}
