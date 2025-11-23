# Release Script for Payment Gateway
# Usage: .\release.ps1 -Version "1.0.0" -Message "Initial release"

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "Release v$Version"
)

Write-Host "?? Payment Gateway Release Script" -ForegroundColor Green
Write-Host "Version: v$Version" -ForegroundColor Cyan
Write-Host ""

# Validate version format (semantic versioning)
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "? Error: Version must be in format X.Y.Z (e.g., 1.0.0)" -ForegroundColor Red
    exit 1
}

# Check if we're in a git repository
if (-not (Test-Path .git)) {
    Write-Host "? Error: Not a git repository!" -ForegroundColor Red
    exit 1
}

# Check if there are uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-Host "??  Warning: You have uncommitted changes:" -ForegroundColor Yellow
    Write-Host $status
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        Write-Host "? Release cancelled" -ForegroundColor Red
        exit 1
    }
}

# Run tests
Write-Host "?? Running tests..." -ForegroundColor Yellow
dotnet test --filter "FullyQualifiedName~UnitTests" --verbosity quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Tests failed! Fix tests before releasing." -ForegroundColor Red
    exit 1
}
Write-Host "? Tests passed!" -ForegroundColor Green

# Build project
Write-Host "?? Building project..." -ForegroundColor Yellow
dotnet build -c Release --verbosity quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "? Build successful!" -ForegroundColor Green

# Build Docker image
Write-Host "?? Building Docker image..." -ForegroundColor Yellow
docker-compose build --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Docker build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "? Docker image built!" -ForegroundColor Green

# Create tag
Write-Host "???  Creating git tag v$Version..." -ForegroundColor Yellow
$tagMessage = @"
$Message

Version: $Version
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

See VERSION.md for full changelog.
"@

git tag -a "v$Version" -m $tagMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Failed to create tag!" -ForegroundColor Red
    exit 1
}
Write-Host "? Tag v$Version created!" -ForegroundColor Green

# Show tag details
Write-Host ""
Write-Host "?? Tag details:" -ForegroundColor Cyan
git show "v$Version" --quiet

# Ask to push
Write-Host ""
$push = Read-Host "Push tag to remote? (y/n)"
if ($push -eq 'y') {
    Write-Host "?? Pushing to remote..." -ForegroundColor Yellow
    
    # Push commits
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "??  Warning: Failed to push commits" -ForegroundColor Yellow
    }
    
    # Push tag
    git push origin "v$Version"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "? Failed to push tag!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "? Tag pushed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "?? Release v$Version completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Create GitHub Release: https://github.com/IanaUlu/Payment-Gateway/releases/new?tag=v$Version" -ForegroundColor White
    Write-Host "2. Deploy to production server" -ForegroundColor White
    Write-Host "3. Update VERSION.md for next release" -ForegroundColor White
} else {
    Write-Host "? Tag created locally (not pushed)" -ForegroundColor Yellow
    Write-Host "To push later, run: git push origin v$Version" -ForegroundColor Cyan
}
