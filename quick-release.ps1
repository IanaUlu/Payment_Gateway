# Quick Release Script - Hızlı Release
# Kullanım: .\quick-release.ps1

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  🚀 Quick Release Tool" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Mevcut branch kontrolü
$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Host "Mevcut branch: " -NoNewline
Write-Host $currentBranch -ForegroundColor Yellow

# Mevcut versiyon
$currentTag = git describe --tags --abbrev=0 2>$null
if (-not $currentTag) {
    $currentTag = "v0.0.0"
}
Write-Host "Mevcut versiyon: " -NoNewline
Write-Host $currentTag -ForegroundColor Yellow

Write-Host "`nHangi tip release yapmak istiyorsunuz?" -ForegroundColor Cyan
Write-Host "1. Patch (Bug fix)       - v1.0.0 -> v1.0.1" -ForegroundColor White
Write-Host "2. Minor (Yeni özellik)  - v1.0.0 -> v1.1.0" -ForegroundColor White
Write-Host "3. Major (Breaking change) - v1.0.0 -> v2.0.0" -ForegroundColor White
Write-Host "4. İptal" -ForegroundColor Red

$choice = Read-Host "`nSeçiminiz (1-4)"

switch ($choice) {
    "1" { 
        & ".\version-bump.ps1" -Type patch
    }
    "2" { 
        & ".\version-bump.ps1" -Type minor
    }
    "3" { 
        & ".\version-bump.ps1" -Type major
    }
    "4" {
        Write-Host "İşlem iptal edildi." -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host "Geçersiz seçim!" -ForegroundColor Red
        exit 1
    }
}
