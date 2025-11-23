# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["QiwiGateway.Api/QiwiGateway.Api.csproj", "QiwiGateway.Api/"]
COPY ["QiwiGateway.Application/QiwiGateway.Application.csproj", "QiwiGateway.Application/"]
COPY ["QiwiGateway.Domain/QiwiGateway.Domain.csproj", "QiwiGateway.Domain/"]
COPY ["QiwiGateway.Infrastructure/QiwiGateway.Infrastructure.csproj", "QiwiGateway.Infrastructure/"]

# Restore dependencies
RUN dotnet restore "QiwiGateway.Api/QiwiGateway.Api.csproj"

# Copy all source code
COPY . .

# Build and publish
WORKDIR "/src/QiwiGateway.Api"
RUN dotnet build "QiwiGateway.Api.csproj" -c Release -o /app/build
RUN dotnet publish "QiwiGateway.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Install wget for healthcheck
USER root
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r qiwi && useradd -r -g qiwi qiwi

# Copy published files from build stage
COPY --from=build /app/publish .

# Create Logs directory and set permissions
RUN mkdir -p /app/Logs && chown -R qiwi:qiwi /app

# Switch to non-root user
USER qiwi

# Expose port
EXPOSE 5000

# Run application
ENTRYPOINT ["dotnet", "QiwiGateway.Api.dll"]
