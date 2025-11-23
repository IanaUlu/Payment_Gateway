# Git & Versiyon Yönetimi Scriptleri

Bu klasörde projenin git iş akışı ve versiyon yönetimi için otomatik scriptler bulunur.

## 📁 Script'ler

### 1. `quick-release.ps1` - Hızlı Release
En basit kullanım! Tek tıkla versiyon yükselt ve release yap.

```powershell
.\quick-release.ps1
```

**Ne yapar?**
- Menüden patch/minor/major seçersin
- Otomatik versiyon yükseltir
- Tag oluşturur
- GitHub'a gönderir

---

### 2. `version-bump.ps1` - Manuel Versiyon Yükseltme
Daha kontrollu versiyon yönetimi için.

```powershell
# Patch version (1.0.0 -> 1.0.1) - Bug fix
.\version-bump.ps1 -Type patch

# Minor version (1.0.0 -> 1.1.0) - Yeni özellik
.\version-bump.ps1 -Type minor

# Major version (1.0.0 -> 2.0.0) - Breaking change
.\version-bump.ps1 -Type major
```

**Ne yapar?**
- VERSION.md dosyasını günceller
- Git tag oluşturur
- GitHub'a push eder
- Commit edilmemiş değişiklikleri sorar

---

### 3. `git-workflow.ps1` - Tam Git İş Akışı Yönetimi
Feature branch'leri yönet, merge işlemlerini otomatikleştir.

```powershell
# İnteraktif menü
.\git-workflow.ps1

# Veya komut satırından direkt:
.\git-workflow.ps1 -Action new -FeatureName "payment-webhook"
.\git-workflow.ps1 -Action merge
.\git-workflow.ps1 -Action release
.\git-workflow.ps1 -Action status
```

**İnteraktif Menü:**
1. Yeni feature branch oluştur
2. Feature'ı develop'a merge et
3. Develop'ı main'e merge et (Release)
4. Mevcut branch durumunu göster
5. Çıkış

---

## 🔄 Önerilen İş Akışı

### Yeni Özellik Geliştirme

```powershell
# 1. Feature branch oluştur
.\git-workflow.ps1 -Action new -FeatureName "yeni-ozellik"

# 2. Geliştirmeyi yap
# ... kod yaz ...
git add .
git commit -m "feat: yeni özellik eklendi"

# 3. Feature'ı develop'a merge et
.\git-workflow.ps1 -Action merge

# 4. Test et develop branch'inde
```

### Production Release

```powershell
# 1. Develop'ı main'e merge et
.\git-workflow.ps1 -Action release

# 2. Versiyon yükselt ve tag oluştur
.\quick-release.ps1
# veya
.\version-bump.ps1 -Type minor
```

---

## 📋 Commit Mesaj Kuralları

Semantic Commit Messages kullanıyoruz:

- `feat:` - Yeni özellik
- `fix:` - Bug fix
- `docs:` - Dokümantasyon
- `style:` - Kod formatı (loglama, boşluk vs)
- `refactor:` - Kod refactor
- `test:` - Test ekleme
- `chore:` - Bakım işleri (dependency update vs)

**Örnekler:**
```
feat: add webhook support for QIWI payments
fix: resolve transaction timeout issue
docs: update API documentation
refactor: improve error handling in payment service
```

---

## 🏷️ Versiyon Numaralandırma

**Semantic Versioning (SemVer):** `MAJOR.MINOR.PATCH`

- **MAJOR (1.0.0 → 2.0.0)**: Breaking changes - API değişiklikleri
- **MINOR (1.0.0 → 1.1.0)**: Yeni özellikler - backward compatible
- **PATCH (1.0.0 → 1.0.1)**: Bug fix'ler - backward compatible

---

## 🌿 Branch Stratejisi

```
main (production)
  ↑
  merge when stable
  ↑
develop (development)
  ↑
  merge when feature complete
  ↑
feature/payment-webhook
feature/refund-api
feature/new-provider
```

- `main` → Sadece production-ready kod
- `develop` → Geliştirme branch'i
- `feature/*` → Her özellik için ayrı branch

---

## 🚀 Hızlı Başlangıç

```powershell
# Yeni özellik başlat
.\git-workflow.ps1

# Menüden 1'i seç -> feature adı gir -> geliştir

# Bitince tekrar çalıştır
.\git-workflow.ps1

# Menüden 2'yi seç -> develop'a merge et

# Release için
.\quick-release.ps1
```

---

## 💡 İpuçları

1. **Her zaman develop branch'inde çalış** - main'e direkt commit yapma
2. **Küçük, sık commit'ler yap** - Atomic commits
3. **Feature branch'leri temiz tut** - Bir özellik = bir branch
4. **Release öncesi test et** - develop'da test et, sonra main'e merge et
5. **Semantic commit mesajları kullan** - Changelog otomatik oluşturulabilir

---

## 🔧 Sorun Giderme

### Script çalışmıyor?
```powershell
# PowerShell execution policy ayarla
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Git tag'leri görünmüyor?
```powershell
git fetch --tags
```

### Branch'ler karışık?
```powershell
.\git-workflow.ps1 -Action status
```

---

## 📞 Ek Bilgi

Bu scriptler ile:
- ✅ Otomatik versiyon yönetimi
- ✅ Kolay branch yönetimi
- ✅ Tutarlı release süreci
- ✅ Git best practices

Mutlu kodlamalar! 🎉
