# PowerShell Deploy Script - TEST Environment
# Usage: .\deploy-test.ps1

param(
    [switch]$Force
)

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  🧪 DEPLOYING TO TEST ENVIRONMENT" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Configuration
$Branch = "develop"
$ComposeFile = "docker-compose.test.yml"
$EnvFile = ".env.test"

Write-Host "📋 Pre-deployment checks..." -ForegroundColor Yellow

# Check if docker is running
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running!" -ForegroundColor Red
    exit 1
}

# Check git status
$gitStatus = git status -s
if ($gitStatus -and -not $Force) {
    Write-Host "⚠️  Warning: You have uncommitted changes" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit 1
    }
}

Write-Host "✓ Pre-checks passed" -ForegroundColor Green

# Pull latest code
Write-Host "`n📥 Pulling latest code from $Branch..." -ForegroundColor Yellow
git fetch origin
git checkout $Branch
git pull origin $Branch

Write-Host "✓ Code updated" -ForegroundColor Green

# Load environment variables
if (Test-Path $EnvFile) {
    Write-Host "`n🔧 Loading test environment variables..." -ForegroundColor Yellow
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
    Write-Host "✓ Environment loaded" -ForegroundColor Green
} else {
    Write-Host "⚠️  $EnvFile not found, using defaults" -ForegroundColor Yellow
}

# Stop existing containers
Write-Host "`n🛑 Stopping existing test containers..." -ForegroundColor Yellow
docker-compose -f $ComposeFile down

# Build new images
Write-Host "`n🏗️  Building new images..." -ForegroundColor Yellow
docker-compose -f $ComposeFile build --no-cache

# Start containers
Write-Host "`n🚀 Starting test environment..." -ForegroundColor Yellow
docker-compose -f $ComposeFile up -d

# Wait for services
Write-Host "`n⏳ Waiting for services to be healthy..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check container status
$containers = docker-compose -f $ComposeFile ps
if ($containers -match "Up") {
    Write-Host "✓ Containers are running" -ForegroundColor Green
} else {
    Write-Host "❌ Some containers failed to start" -ForegroundColor Red
    docker-compose -f $ComposeFile logs --tail=50
    exit 1
}

# Health check
Write-Host "`n🏥 Running health checks..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://localhost:5001/health" -UseBasicParsing -TimeoutSec 10
    Write-Host "✓ API health check passed" -ForegroundColor Green
} catch {
    Write-Host "❌ API health check failed" -ForegroundColor Red
    docker-compose -f $ComposeFile logs api_test --tail=50
    exit 1
}

# Success
Write-Host "`n======================================" -ForegroundColor Green
Write-Host "  ✅ TEST DEPLOYMENT SUCCESSFUL" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

Write-Host "📊 Container Status:" -ForegroundColor Cyan
docker-compose -f $ComposeFile ps

Write-Host "`n🌐 Test API: http://localhost:5001" -ForegroundColor Cyan
Write-Host "🔍 Swagger: http://localhost:5001/swagger" -ForegroundColor Cyan
Write-Host "🗄️  Database: localhost:5434`n" -ForegroundColor Cyan

Write-Host "📋 Useful commands:" -ForegroundColor Yellow
Write-Host "  View logs:    docker-compose -f $ComposeFile logs -f"
Write-Host "  Stop:         docker-compose -f $ComposeFile down"
Write-Host "  Restart:      docker-compose -f $ComposeFile restart`n"
