# PowerShell Deploy Script - PRODUCTION Environment
# Usage: .\deploy-production.ps1

param(
    [switch]$SkipBackup,
    [switch]$Force
)

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  🚀 DEPLOYING TO PRODUCTION" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Configuration
$Branch = "main"
$ComposeFile = "docker-compose.production.yml"
$EnvFile = ".env.production"
$BackupDir = "./backups"

# Production confirmation
Write-Host "⚠️  WARNING: You are about to deploy to PRODUCTION!" -ForegroundColor Red
Write-Host ""
if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`n📋 Pre-deployment checks..." -ForegroundColor Yellow

# Check if docker is running
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running!" -ForegroundColor Red
    exit 1
}

# Check current branch
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne $Branch) {
    Write-Host "❌ Must be on $Branch branch (currently on $currentBranch)" -ForegroundColor Red
    exit 1
}

# Check git status
$gitStatus = git status -s
if ($gitStatus) {
    Write-Host "❌ You have uncommitted changes. Commit them first!" -ForegroundColor Red
    exit 1
}

# Check environment file
if (-not (Test-Path $EnvFile)) {
    Write-Host "❌ $EnvFile not found!" -ForegroundColor Red
    Write-Host "Create it with: cp .env.production.example $EnvFile" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Pre-checks passed" -ForegroundColor Green

# Pull latest code
Write-Host "`n📥 Pulling latest code from $Branch..." -ForegroundColor Yellow
git fetch origin
git pull origin $Branch

$commitHash = git rev-parse --short HEAD
Write-Host "Deploying commit: $commitHash" -ForegroundColor Blue

Write-Host "✓ Code updated" -ForegroundColor Green

# Load environment variables
Write-Host "`n🔧 Loading production environment variables..." -ForegroundColor Yellow
Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}
Write-Host "✓ Environment loaded" -ForegroundColor Green

# Create backup directory
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

# Backup database
if (-not $SkipBackup) {
    Write-Host "`n💾 Creating database backup..." -ForegroundColor Yellow
    $backupFile = "$BackupDir/backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
    
    $containerExists = docker ps --filter "name=qiwi_postgres_prod" --format "{{.Names}}"
    if ($containerExists) {
        $postgresUser = $env:POSTGRES_USER
        if (-not $postgresUser) { $postgresUser = "qiwi_prod_user" }
        
        docker exec qiwi_postgres_prod pg_dump -U $postgresUser qiwi_gateway_prod > $backupFile
        Write-Host "✓ Backup created: $backupFile" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No running database to backup" -ForegroundColor Yellow
    }
}

# Stop existing containers
Write-Host "`n🛑 Stopping existing production containers..." -ForegroundColor Yellow
docker-compose -f $ComposeFile down --timeout 30

# Build new images
Write-Host "`n🏗️  Building production images..." -ForegroundColor Yellow
docker-compose -f $ComposeFile build --no-cache

# Start containers
Write-Host "`n🚀 Starting production environment..." -ForegroundColor Yellow
docker-compose -f $ComposeFile up -d

# Wait for services
Write-Host "`n⏳ Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check container status with retries
$maxRetries = 6
$retryCount = 0
$success = $false

while ($retryCount -lt $maxRetries) {
    $containers = docker-compose -f $ComposeFile ps
    if ($containers -match "Up") {
        Write-Host "✓ Containers are running" -ForegroundColor Green
        $success = $true
        break
    }
    
    $retryCount++
    if ($retryCount -eq $maxRetries) {
        Write-Host "❌ Containers failed to start" -ForegroundColor Red
        docker-compose -f $ComposeFile logs --tail=50
        
        # Rollback
        Write-Host "`n🔄 Rolling back..." -ForegroundColor Yellow
        docker-compose -f $ComposeFile down
        exit 1
    }
    
    Write-Host "Retry $retryCount/$maxRetries..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Health check with retries
Write-Host "`n🏥 Running health checks..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$maxHealthRetries = 5
$healthRetryCount = 0
$healthSuccess = $false

while ($healthRetryCount -lt $maxHealthRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 10
        Write-Host "✓ API health check passed" -ForegroundColor Green
        $healthSuccess = $true
        break
    } catch {
        $healthRetryCount++
        if ($healthRetryCount -eq $maxHealthRetries) {
            Write-Host "❌ API health check failed" -ForegroundColor Red
            docker-compose -f $ComposeFile logs api --tail=50
            exit 1
        }
        Write-Host "Health check retry $healthRetryCount/$maxHealthRetries..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}

# Cleanup old images
Write-Host "`n🧹 Cleaning up old images..." -ForegroundColor Yellow
docker image prune -f

# Success
Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  ✅ PRODUCTION DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

Write-Host "📊 Deployment Info:" -ForegroundColor Cyan
Write-Host "  Commit:    $commitHash"
Write-Host "  Time:      $(Get-Date)"
if (-not $SkipBackup) {
    Write-Host "  Backup:    $backupFile"
}

Write-Host "`n📊 Container Status:" -ForegroundColor Cyan
docker-compose -f $ComposeFile ps

Write-Host "`n🌐 Production API: http://localhost:5000" -ForegroundColor Cyan
Write-Host "🗄️  Database: localhost:5433 (localhost only)`n" -ForegroundColor Cyan

Write-Host "📋 Useful commands:" -ForegroundColor Yellow
Write-Host "  View logs:    docker-compose -f $ComposeFile logs -f"
Write-Host "  Stop:         docker-compose -f $ComposeFile down"
Write-Host "  Restart:      docker-compose -f $ComposeFile restart`n"

Write-Host "💡 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Monitor logs for errors"
Write-Host "  2. Run smoke tests"
Write-Host "  3. Update monitoring/alerting`n"
