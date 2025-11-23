# Test Docker build locally (Windows)

Write-Host "?? Testing Docker build locally..." -ForegroundColor Green

# Check if Docker is running
docker ps > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host "? Docker is running" -ForegroundColor Green

# Build the image
Write-Host "`n?? Building Docker image..." -ForegroundColor Yellow
docker-compose build

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Build successful!" -ForegroundColor Green
    
    Write-Host "`n?? Starting containers..." -ForegroundColor Yellow
    docker-compose up -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "? Containers started!" -ForegroundColor Green
        
        Write-Host "`n? Waiting for services to be ready (30 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
        Write-Host "`n?? Container status:" -ForegroundColor Cyan
        docker-compose ps
        
        Write-Host "`n?? Testing health endpoint..." -ForegroundColor Yellow
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing
            Write-Host "? Health check passed: $($response.StatusCode)" -ForegroundColor Green
            Write-Host $response.Content
        }
        catch {
            Write-Host "??  Health check failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "`n?? Testing API endpoint..." -ForegroundColor Yellow
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5000/payment_app.cgi?command=check&txn_id=TEST001&account=123456&sum=100&prv_id=100001" -UseBasicParsing
            Write-Host "? API test passed: $($response.StatusCode)" -ForegroundColor Green
            Write-Host $response.Content
        }
        catch {
            Write-Host "??  API test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "`n?? View logs with: docker-compose logs -f" -ForegroundColor Cyan
        Write-Host "?? Stop with: docker-compose down" -ForegroundColor Cyan
    }
    else {
        Write-Host "? Failed to start containers" -ForegroundColor Red
        docker-compose logs
    }
}
else {
    Write-Host "? Build failed" -ForegroundColor Red
}
