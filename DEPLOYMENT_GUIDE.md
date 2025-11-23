# 🚀 Deployment Guide - Test & Production Environments

Bu rehber, QIWI Gateway API'sini Test ve Production ortamlarına deploy etme sürecini açıklar.

## 📋 İçindekiler

- [Ortam Yapısı](#ortam-yapısı)
- [Hızlı Başlangıç](#hızlı-başlangıç)
- [Test Ortamı Deployment](#test-ortamı-deployment)
- [Production Ortamı Deployment](#production-ortamı-deployment)
- [Nginx Reverse Proxy](#nginx-reverse-proxy)
- [SSL Sertifikası](#ssl-sertifikası)
- [Monitoring & Logging](#monitoring--logging)
- [Sorun Giderme](#sorun-giderme)

---

## 🏗️ Ortam Yapısı

```
┌─────────────────────────────────────────┐
│         GIT REPOSITORY                  │
│  ┌──────────┐  ┌──────────┐            │
│  │  develop │→ │   main   │            │
│  └──────────┘  └──────────┘            │
└──────┬──────────────┬──────────────────┘
       │              │
       │ Auto Deploy  │ Manual Deploy
       ▼              ▼
┌─────────────┐  ┌─────────────┐
│ TEST SERVER │  │ PROD SERVER │
│             │  │             │
│ Port: 5001  │  │ Port: 5000  │
│ DB: 5434    │  │ DB: 5433    │
└─────────────┘  └─────────────┘
```

### Ortam Karşılaştırması

| Özellik | Test | Production |
|---------|------|------------|
| **Branch** | develop | main |
| **API Port** | 5001 | 5000 |
| **DB Port** | 5434 (localhost) | 5433 (localhost) |
| **Swagger** | Enabled ✅ | Disabled ❌ |
| **Detailed Errors** | Enabled ✅ | Disabled ❌ |
| **Logging Level** | Debug | Warning |
| **Auto Backup** | ❌ | ✅ |
| **Health Checks** | Basic | Advanced |
| **Rate Limiting** | Disabled | Enabled (100/min) |

---

## ⚡ Hızlı Başlangıç

### 1. Gereksinimler

```bash
# Linux Server (Ubuntu 22.04 LTS recommended)
- Docker 20.10+
- Docker Compose 2.0+
- Git
- 4GB RAM minimum
- 20GB Disk space
```

### 2. İlk Kurulum

```bash
# Repository'yi clone et
git clone https://github.com/IanaUlu/Payment_Gateway.git
cd Payment_Gateway

# Environment dosyalarını oluştur
cp .env.test.example .env.test
cp .env.production.example .env.production

# ÖNEMLI: .env.production dosyasındaki şifreleri değiştir!
nano .env.production
```

---

## 🧪 Test Ortamı Deployment

Test ortamı, `develop` branch'indeki değişiklikleri test etmek için kullanılır.

### Linux/Mac Deployment

```bash
# Deploy script'i çalıştırılabilir yap
chmod +x deploy-test.sh

# Deploy et
./deploy-test.sh
```

### Windows (PowerShell) Deployment

```powershell
# Deploy et
.\deploy-test.ps1

# Zorla deploy (git kontrolü atla)
.\deploy-test.ps1 -Force
```

### Manuel Deployment

```bash
# develop branch'ine geç
git checkout develop
git pull origin develop

# Environment değişkenlerini yükle
source .env.test

# Docker container'ları başlat
docker-compose -f docker-compose.test.yml up -d --build

# Logları kontrol et
docker-compose -f docker-compose.test.yml logs -f
```

### Test Ortamı Erişim

```
🌐 API: http://localhost:5001
🔍 Swagger: http://localhost:5001/swagger
🏥 Health: http://localhost:5001/health
🗄️  Database: localhost:5434
```

---

## 🚀 Production Ortamı Deployment

Production ortamı, `main` branch'indeki stabil kodu canlıya almak için kullanılır.

### ⚠️ Önemli Ön Hazırlık

```bash
# 1. .env.production dosyasını güvenli şifrelerle ayarla
nano .env.production

# 2. main branch'inde olduğundan emin ol
git checkout main

# 3. Tüm değişiklikler commit edilmiş olmalı
git status  # Temiz olmalı

# 4. Son değişiklikleri çek
git pull origin main
```

### Linux/Mac Deployment

```bash
# Deploy script'i çalıştırılabilir yap
chmod +x deploy-production.sh

# Deploy et (onay ister)
./deploy-production.sh
```

### Windows (PowerShell) Deployment

```powershell
# Deploy et (onay ister)
.\deploy-production.ps1

# Backup'sız deploy
.\deploy-production.ps1 -SkipBackup

# Onay istemeden deploy (dikkatli kullan!)
.\deploy-production.ps1 -Force
```

### Manuel Deployment

```bash
# main branch'ine geç
git checkout main
git pull origin main

# Environment değişkenlerini yükle
source .env.production

# Veritabanı backup al
docker exec qiwi_postgres_prod pg_dump -U qiwi_prod_user qiwi_gateway_prod > backup_$(date +%Y%m%d_%H%M%S).sql

# Docker container'ları güncelle
docker-compose -f docker-compose.production.yml down --timeout 30
docker-compose -f docker-compose.production.yml up -d --build

# Health check
curl http://localhost:5000/health

# Logları kontrol et
docker-compose -f docker-compose.production.yml logs -f api
```

### Production Ortamı Erişim

```
🌐 API: http://localhost:5000
🏥 Health: http://localhost:5000/health
🗄️  Database: localhost:5433 (sadece localhost erişimi)
```

---

## 🔒 Nginx Reverse Proxy (Production)

Domain ve SSL kullanmak için nginx reverse proxy ekleyin.

### 1. SSL Sertifikası Alma (Let's Encrypt)

```bash
# Certbot kur
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# SSL sertifikası al
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### 2. Nginx Konfigürasyonu

```bash
# nginx.conf dosyasını düzenle
nano nginx/nginx.conf

# Domain adını değiştir
server_name yourdomain.com www.yourdomain.com;

# SSL sertifika yollarını güncelle
ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
```

### 3. Nginx ile Production Başlat

docker-compose.production.yml dosyasında nginx servisini uncomment edin:

```yaml
# nginx:
#   image: nginx:alpine
#   ...
```

Sonra:

```bash
docker-compose -f docker-compose.production.yml up -d nginx
```

### Domain ile Erişim

```
🌐 API: https://yourdomain.com/api/
🏥 Health: https://yourdomain.com/health
📄 Landing: https://yourdomain.com
```

---

## 📊 Monitoring & Logging

### Log Dosyaları

```bash
# Test ortamı logları
./logs-test/

# Production ortamı logları
./logs/

# Nginx logları
./nginx/logs/
```

### Log İzleme

```bash
# API logları (canlı)
docker-compose -f docker-compose.production.yml logs -f api

# Database logları
docker-compose -f docker-compose.production.yml logs -f postgres

# Son 100 satır
docker logs qiwi_api_prod --tail 100

# Hata logları filtrele
docker logs qiwi_api_prod 2>&1 | grep -i error
```

### Health Check

```bash
# API health check
curl http://localhost:5000/health

# Database health check
docker exec qiwi_postgres_prod pg_isready -U qiwi_prod_user

# Container status
docker-compose -f docker-compose.production.yml ps
```

---

## 🔄 Database Backup & Restore

### Manuel Backup

```bash
# Production veritabanı backup
docker exec qiwi_postgres_prod pg_dump -U qiwi_prod_user qiwi_gateway_prod > backup.sql

# Compression ile
docker exec qiwi_postgres_prod pg_dump -U qiwi_prod_user qiwi_gateway_prod | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Restore

```bash
# Backup'tan restore
cat backup.sql | docker exec -i qiwi_postgres_prod psql -U qiwi_prod_user qiwi_gateway_prod

# Compressed backup'tan
gunzip -c backup.sql.gz | docker exec -i qiwi_postgres_prod psql -U qiwi_prod_user qiwi_gateway_prod
```

### Otomatik Backup (Cron)

```bash
# Crontab düzenle
crontab -e

# Her gün 02:00'de backup al (30 gün sakla)
0 2 * * * cd /path/to/Payment_Gateway && docker exec qiwi_postgres_prod pg_dump -U qiwi_prod_user qiwi_gateway_prod | gzip > backups/backup_$(date +\%Y\%m\%d).sql.gz && find backups/ -name "*.gz" -mtime +30 -delete
```

---

## 🛠️ Sorun Giderme

### Container Başlamıyor

```bash
# Container loglarını kontrol et
docker-compose -f docker-compose.production.yml logs

# Belirli bir container'ı yeniden başlat
docker-compose -f docker-compose.production.yml restart api

# Container'ları temizle ve yeniden başlat
docker-compose -f docker-compose.production.yml down
docker system prune -f
docker-compose -f docker-compose.production.yml up -d --build
```

### Database Bağlantı Hatası

```bash
# PostgreSQL çalışıyor mu?
docker ps | grep postgres

# Database logları
docker logs qiwi_postgres_prod

# Connection string kontrol et
docker exec qiwi_api_prod env | grep ConnectionStrings
```

### Disk Dolu

```bash
# Disk kullanımı
df -h

# Docker disk kullanımı
docker system df

# Kullanılmayan image/container'ları temizle
docker system prune -a --volumes
```

### Port Zaten Kullanımda

```bash
# Hangi process kullanıyor?
sudo lsof -i :5000

# Process'i durdur
sudo kill -9 <PID>
```

---

## 🔐 Güvenlik Best Practices

1. **Şifreleri Güvenli Tut**
   - `.env.production` dosyasını git'e ekleme
   - Güçlü şifreler kullan (minimum 32 karakter)
   - Düzenli olarak şifreleri değiştir

2. **Database Erişimi**
   - Database portunu sadece localhost'a bind et
   - Firewall kuralları ile API dışında erişimi engelle

3. **SSL/TLS**
   - Production'da mutlaka HTTPS kullan
   - Let's Encrypt ile ücretsiz SSL
   - Auto-renewal kur

4. **Rate Limiting**
   - Production'da rate limiting aktif
   - Nginx seviyesinde ek koruma

5. **Monitoring**
   - Düzenli log kontrolü
   - Health check monitoring
   - Uptime monitoring (UptimeRobot, Pingdom)

---

## 📞 Destek

Sorun yaşarsanız:

1. Logları kontrol edin
2. Health endpoint'leri test edin
3. GitHub Issues açın

---

**Son Güncelleme:** 2025-11-23
