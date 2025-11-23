# Payment Gateway - Otomatik GitHub Yükleme Scripti
# Kullan?m: .\push-to-github.ps1

Write-Host @"
??????????????????????????????????????????????????????????????
?                                                            ?
?        ?? Payment Gateway GitHub Otomatik Yükleme ??       ?
?                                                            ?
??????????????????????????????????????????????????????????????
"@ -ForegroundColor Cyan

Write-Host "`n??  Ba?lat?l?yor..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

# Dizine git
Set-Location "C:\Users\ibogd\Source\QiwiGateway"

# Kontrol: Git repository var m??
if (-not (Test-Path .git)) {
    Write-Host "? HATA: Bu bir Git repository de?il!" -ForegroundColor Red
    exit 1
}

# 1. Durum kontrolü
Write-Host "`n?? Git durumu kontrol ediliyor..." -ForegroundColor Cyan
$status = git status --short
if ($status) {
    Write-Host "? De?i?iklikler bulundu, devam ediliyor..." -ForegroundColor Green
}

# 2. Tüm dosyalar? ekle
Write-Host "`n?? Tüm dosyalar ekleniyor..." -ForegroundColor Cyan
git add .

# 3. Commit yap
Write-Host "`n?? Commit yap?l?yor..." -ForegroundColor Cyan
$commitMessage = @"
Release v1.0.0: Payment Gateway - Production Ready

? Features:
- QIWI Payment Protocol integration
- Docker & Docker Compose containerization
- PostgreSQL 15 database with auto-migrations
- Clean Architecture (Domain, Application, Infrastructure, API)
- CQRS pattern with MediatR
- Comprehensive logging system
- Health monitoring endpoints
- Swagger/OpenAPI documentation
- Unit tests (20 tests)
- Production deployment scripts
- Version management system

?? Deployment:
- Docker-ready with docker-compose.yml
- Ubuntu server deployment scripts
- Automated database setup

?? Documentation:
- Quick Start Guide
- Full Deployment Guide
- Version management
- Git workflow guidelines

Ready for production deployment!
"@

git commit -m $commitMessage

# 4. Remote de?i?tir
Write-Host "`n?? Remote repository de?i?tiriliyor..." -ForegroundColor Cyan
try {
    git remote remove origin 2>$null
} catch {
    Write-Host "  ??  Eski remote yok, devam ediliyor..." -ForegroundColor Gray
}

git remote add origin https://github.com/IanaUlu/Payment-Gateway.git
Write-Host "? Remote ayarland?: Payment-Gateway" -ForegroundColor Green

# 5. main branch'i push et
Write-Host "`n?? main branch GitHub'a gönderiliyor..." -ForegroundColor Cyan
git push -u origin main --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "? main branch ba?ar?yla push edildi!" -ForegroundColor Green
} else {
    Write-Host "? main branch push edilemedi!" -ForegroundColor Red
    Write-Host "??  GitHub'da Payment-Gateway repository'sini olu?turdun mu?" -ForegroundColor Yellow
    Write-Host "   https://github.com/new" -ForegroundColor Cyan
    exit 1
}

# 6. development branch olu?tur
Write-Host "`n?? development branch olu?turuluyor..." -ForegroundColor Cyan
git checkout -b development
git push -u origin development

if ($LASTEXITCODE -eq 0) {
    Write-Host "? development branch ba?ar?yla olu?turuldu!" -ForegroundColor Green
} else {
    Write-Host "??  development branch zaten var veya push edilemedi" -ForegroundColor Yellow
}

# 7. main'e geri dön
git checkout main

# 8. v1.0.0 tag olu?tur
Write-Host "`n???  v1.0.0 tag olu?turuluyor..." -ForegroundColor Cyan
$tagMessage = @"
Release v1.0.0 - Initial Production Release

?? Payment Gateway v1.0.0 - ?lk Stabil Sürüm

Özellikler:
? QIWI Payment Protocol entegrasyonu
? Docker & Docker Compose haz?r
? PostgreSQL 15 veritaban?
? Clean Architecture (CQRS + MediatR)
? Otomatik veritaban? migrasyonlar?
? Kapsaml? loglama sistemi
? Health monitoring
? Swagger API dokümantasyonu
? Unit testler (20 test)
? Production deployment scriptleri

?? Tarih: $(Get-Date -Format 'yyyy-MM-dd')

Detayl? changelog için VERSION.md dosyas?na bak?n.
"@

try {
    git tag -d v1.0.0 2>$null
} catch {
    # Tag yoksa devam et
}

git tag -a v1.0.0 -m $tagMessage
Write-Host "? Tag olu?turuldu: v1.0.0" -ForegroundColor Green

# 9. Tag'i push et
Write-Host "`n?? Tag GitHub'a gönderiliyor..." -ForegroundColor Cyan
git push origin v1.0.0 --force
git push origin --tags

if ($LASTEXITCODE -eq 0) {
    Write-Host "? Tag ba?ar?yla push edildi!" -ForegroundColor Green
}

# 10. Özet
Write-Host @"

??????????????????????????????????????????????????????????????
?                                                            ?
?                    ? BA?ARILI! ?                          ?
?                                                            ?
?          Payment Gateway GitHub'a yüklendi! ??            ?
?                                                            ?
??????????????????????????????????????????????????????????????

"@ -ForegroundColor Green

Write-Host "?? ÖZET:" -ForegroundColor Cyan
Write-Host "  ?????????????????????????????????????????????" -ForegroundColor Gray
Write-Host "  ?? Repository  : Payment-Gateway" -ForegroundColor White
Write-Host "  ?? Branch'ler : main, development" -ForegroundColor White
Write-Host "  ???  Tag        : v1.0.0" -ForegroundColor White
Write-Host "  ?? Remote      : https://github.com/IanaUlu/Payment-Gateway.git" -ForegroundColor White
Write-Host "  ?????????????????????????????????????????????" -ForegroundColor Gray

# Branch'leri göster
Write-Host "`n?? Local Branch'ler:" -ForegroundColor Cyan
git branch

Write-Host "`n?? Remote Branch'ler:" -ForegroundColor Cyan
git branch -r

# Tag'leri göster
Write-Host "`n???  Tag'ler:" -ForegroundColor Cyan
git tag -l

# GitHub'? aç
Write-Host "`n?? GitHub aç?l?yor..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Start-Process "https://github.com/IanaUlu/Payment-Gateway"

Write-Host @"

??????????????????????????????????????????????????????????

? SONRAKI ADIMLAR:

1. ?? GitHub'da repository'yi kontrol et
2. ???  GitHub Release olu?tur (opsiyonel):
   https://github.com/IanaUlu/Payment-Gateway/releases/new?tag=v1.0.0

3. ?? Production'a deploy et:
   ssh user@server
   git clone https://github.com/IanaUlu/Payment-Gateway.git
   cd Payment-Gateway
   docker-compose up -d

??????????????????????????????????????????????????????????

"@ -ForegroundColor Cyan

Write-Host "? ??lem tamamland?! Keyifli kodlamalar! ??`n" -ForegroundColor Green
