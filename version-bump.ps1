# Otomatik Versiyon Yükseltme ve Taglama Scripti
# Kullanım: .\version-bump.ps1 -Type [major|minor|patch]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("major", "minor", "patch")]
    [string]$Type
)

# Mevcut versiyonu al
$currentTag = git describe --tags --abbrev=0 2>$null
if (-not $currentTag) {
    $currentTag = "v0.0.0"
    Write-Host "İlk versiyon oluşturuluyor..." -ForegroundColor Yellow
}

# v'yi kaldır ve parçalara ayır
$version = $currentTag -replace "^v", ""
$parts = $version -split "\."
$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]

# Versiyonu yükselt
switch ($Type) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
        $changeType = "MAJOR RELEASE 🚀"
    }
    "minor" {
        $minor++
        $patch = 0
        $changeType = "MINOR RELEASE ✨"
    }
    "patch" {
        $patch++
        $changeType = "PATCH RELEASE 🔧"
    }
}

$newVersion = "v$major.$minor.$patch"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Versiyon Yükseltme" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mevcut Versiyon: " -NoNewline
Write-Host $currentTag -ForegroundColor Yellow
Write-Host "Yeni Versiyon:   " -NoNewline
Write-Host $newVersion -ForegroundColor Green
Write-Host "Değişiklik Tipi: " -NoNewline
Write-Host $changeType -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Cyan

# Kullanıcıdan onay al
$confirmation = Read-Host "Devam etmek istiyor musunuz? (E/H)"
if ($confirmation -ne 'E' -and $confirmation -ne 'e') {
    Write-Host "İşlem iptal edildi." -ForegroundColor Red
    exit 1
}

# Değişiklikleri kontrol et
$status = git status --porcelain
if ($status) {
    Write-Host "`nCommit edilmemiş değişiklikler var:" -ForegroundColor Yellow
    git status --short
    
    $commitConfirm = Read-Host "`nDeğişiklikleri commit edip devam et? (E/H)"
    if ($commitConfirm -eq 'E' -or $commitConfirm -eq 'e') {
        git add .
        $commitMessage = Read-Host "Commit mesajı"
        if (-not $commitMessage) {
            $commitMessage = "chore: prepare for $newVersion release"
        }
        git commit -m $commitMessage
        Write-Host "✓ Değişiklikler commit edildi" -ForegroundColor Green
    } else {
        Write-Host "Lütfen önce değişiklikleri commit edin." -ForegroundColor Red
        exit 1
    }
}

# VERSION.md dosyasını güncelle
$versionContent = @"
# Version History

## $newVersion ($(Get-Date -Format "yyyy-MM-dd"))

### Changes
- Version bumped from $currentTag to $newVersion
- Type: $Type

## Previous Versions
- $currentTag

"@

if (Test-Path "VERSION.md") {
    $existingContent = Get-Content "VERSION.md" -Raw
    $versionContent = @"
# Version History

## $newVersion ($(Get-Date -Format "yyyy-MM-dd"))

### Changes
- Version bumped from $currentTag to $newVersion
- Type: $Type

$($existingContent -replace '^# Version History\s*', '')
"@
}

Set-Content -Path "VERSION.md" -Value $versionContent -Encoding UTF8
git add VERSION.md
git commit -m "chore: bump version to $newVersion" --allow-empty

Write-Host "✓ VERSION.md güncellendi" -ForegroundColor Green

# Tag oluştur
$tagMessage = "Release $newVersion"
git tag -a $newVersion -m $tagMessage

Write-Host "✓ Tag oluşturuldu: $newVersion" -ForegroundColor Green

# GitHub'a push et
Write-Host "`nGitHub'a gönderiliyor..." -ForegroundColor Cyan

$currentBranch = git rev-parse --abbrev-ref HEAD
git push origin $currentBranch
git push origin $newVersion

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  ✓ BAŞARIYLA TAMAMLANDI" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Yeni versiyon: $newVersion" -ForegroundColor Yellow
Write-Host "Branch: $currentBranch" -ForegroundColor Yellow
Write-Host "Tag GitHub'a gönderildi" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Green
