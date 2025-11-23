# Git İş Akışı Yardımcı Script
# Feature branch oluştur, geliştir ve merge et

param(
    [Parameter(Mandatory=$false)]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$FeatureName
)

function Show-Menu {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  🌿 Git Workflow Helper" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Write-Host "1. Yeni feature branch oluştur" -ForegroundColor Green
    Write-Host "2. Feature'ı develop'a merge et" -ForegroundColor Yellow
    Write-Host "3. Develop'ı main'e merge et (Release)" -ForegroundColor Magenta
    Write-Host "4. Mevcut branch durumunu göster" -ForegroundColor White
    Write-Host "5. Çıkış" -ForegroundColor Red
    
    $choice = Read-Host "`nSeçiminiz (1-5)"
    return $choice
}

function New-FeatureBranch {
    param([string]$Name)
    
    if (-not $Name) {
        $Name = Read-Host "Feature adı (örn: payment-webhook, refund-api)"
    }
    
    # develop branch'ine geç
    git checkout develop
    git pull origin develop
    
    $branchName = "feature/$Name"
    Write-Host "`nOluşturuluyor: $branchName" -ForegroundColor Cyan
    
    git checkout -b $branchName
    git push -u origin $branchName
    
    Write-Host "✓ Feature branch oluşturuldu ve GitHub'a gönderildi!" -ForegroundColor Green
    Write-Host "Şimdi geliştirmeye başlayabilirsin!" -ForegroundColor Yellow
}

function Merge-FeatureToDevelop {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    
    if (-not $currentBranch.StartsWith("feature/")) {
        Write-Host "⚠ Uyarı: Feature branch'inde değilsiniz!" -ForegroundColor Yellow
        Write-Host "Mevcut branch: $currentBranch" -ForegroundColor Yellow
        $continue = Read-Host "Yine de devam et? (E/H)"
        if ($continue -ne 'E' -and $continue -ne 'e') {
            return
        }
    }
    
    # Değişiklikleri commit et
    $status = git status --porcelain
    if ($status) {
        Write-Host "`nCommit edilmemiş değişiklikler var!" -ForegroundColor Yellow
        git status --short
        $commit = Read-Host "`nCommit et? (E/H)"
        if ($commit -eq 'E' -or $commit -eq 'e') {
            git add .
            $message = Read-Host "Commit mesajı"
            git commit -m $message
        }
    }
    
    # Push et
    git push origin $currentBranch
    
    # develop'a geç ve merge et
    Write-Host "`nDevelop'a merge ediliyor..." -ForegroundColor Cyan
    git checkout develop
    git pull origin develop
    git merge $currentBranch --no-ff -m "Merge $currentBranch into develop"
    git push origin develop
    
    Write-Host "✓ $currentBranch başarıyla develop'a merge edildi!" -ForegroundColor Green
    
    $deleteBranch = Read-Host "`nFeature branch'ini sil? (E/H)"
    if ($deleteBranch -eq 'E' -or $deleteBranch -eq 'e') {
        git branch -d $currentBranch
        git push origin --delete $currentBranch
        Write-Host "✓ Feature branch silindi" -ForegroundColor Green
    }
}

function Merge-DevelopToMain {
    Write-Host "`n⚠ DİKKAT: Develop'ı main'e merge ediyorsunuz!" -ForegroundColor Yellow
    Write-Host "Bu işlem production release anlamına gelir." -ForegroundColor Yellow
    
    $confirm = Read-Host "`nDevam et? (E/H)"
    if ($confirm -ne 'E' -and $confirm -ne 'e') {
        Write-Host "İşlem iptal edildi." -ForegroundColor Red
        return
    }
    
    # develop'ı güncelle
    git checkout develop
    git pull origin develop
    
    # main'e geç ve merge et
    git checkout main
    git pull origin main
    git merge develop --no-ff -m "Release: Merge develop into main"
    git push origin main
    
    Write-Host "✓ Develop başarıyla main'e merge edildi!" -ForegroundColor Green
    Write-Host "`nŞimdi versiyonu yükseltmek ister misiniz?" -ForegroundColor Cyan
    $release = Read-Host "(E/H)"
    
    if ($release -eq 'E' -or $release -eq 'e') {
        & ".\quick-release.ps1"
    }
    
    # develop'a geri dön
    git checkout develop
}

function Show-Status {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  📊 Git Durum Bilgisi" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $currentBranch = git rev-parse --abbrev-ref HEAD
    $currentTag = git describe --tags --abbrev=0 2>$null
    
    Write-Host "Mevcut Branch: " -NoNewline
    Write-Host $currentBranch -ForegroundColor Yellow
    Write-Host "Son Tag: " -NoNewline
    Write-Host $currentTag -ForegroundColor Green
    
    Write-Host "`nTüm Branch'ler:" -ForegroundColor Cyan
    git branch -a
    
    Write-Host "`nSon 5 Commit:" -ForegroundColor Cyan
    git log --oneline -5
    
    Write-Host "`nDeğişiklikler:" -ForegroundColor Cyan
    git status --short
}

# Ana akış
if ($Action) {
    switch ($Action) {
        "new" { New-FeatureBranch -Name $FeatureName }
        "merge" { Merge-FeatureToDevelop }
        "release" { Merge-DevelopToMain }
        "status" { Show-Status }
        default { 
            Write-Host "Geçersiz aksiyon! Kullanım: .\git-workflow.ps1 -Action [new|merge|release|status]" -ForegroundColor Red
        }
    }
} else {
    while ($true) {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" { New-FeatureBranch }
            "2" { Merge-FeatureToDevelop }
            "3" { Merge-DevelopToMain }
            "4" { Show-Status }
            "5" { 
                Write-Host "`nGörüşürüz! 👋" -ForegroundColor Cyan
                exit 0
            }
            default { 
                Write-Host "Geçersiz seçim!" -ForegroundColor Red
            }
        }
        
        Write-Host "`nDevam etmek için Enter'a basın..." -ForegroundColor Gray
        Read-Host
    }
}
