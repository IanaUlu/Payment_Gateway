# 🚀 Ubuntu Server Deployment Guide - Separate API & Database

Bu rehber, QIWI Gateway API'sini **iki ayrı Ubuntu server**'a deploy etme sürecini açıklar.

## 📋 Mimari

```
┌──────────────────────────────────────────┐
│      UBUNTU SERVER 1 (API Server)        │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  Docker: Nginx + API Application   │  │
│  │  Ports: 80, 443, 5000              │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Public IP: x.x.x.x (internet erişimi)  │
│  Private IP: 10.0.0.1                   │
└──────────┬───────────────────────────────┘
           │
           │ Private Network
           │ PostgreSQL Connection
           │ SSL/TLS Encrypted
           │
           ▼
┌──────────────────────────────────────────┐
│   UBUNTU SERVER 2 (Database Server)      │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  PostgreSQL 15                     │  │
│  │  Port: 5432 (private only)         │  │
│  │  Automated Daily Backups           │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Private IP: 10.0.0.2 (no internet)     │
└──────────────────────────────────────────┘
```

## ⚡ Hızlı Başlangıç (2 Server)

### Gereksinimler

**Her iki server için:**
- Ubuntu 22.04 LTS (önerilen)
- Root veya sudo yetkisi
- İnternet bağlantısı (kurulum için)

**Server 1 (API):**
- Minimum: 2 CPU, 2GB RAM, 20GB Disk
- Önerilen: 4 CPU, 4GB RAM, 50GB Disk
- Public IP gerekli

**Server 2 (Database):**
- Minimum: 2 CPU, 4GB RAM, 50GB Disk
- Önerilen: 4 CPU, 8GB RAM, 100GB SSD
- Private IP yeterli (daha güvenli)

### 📦 Kurulum Adımları

#### 1️⃣ Database Server'ı Kur (Server 2)

```bash
# Server 2'ye bağlan
ssh root@your-db-server-ip

# Script'i indir
wget https://raw.githubusercontent.com/IanaUlu/Payment_Gateway/main/setup-ubuntu-db-server.sh

# Çalıştırılabilir yap
chmod +x setup-ubuntu-db-server.sh

# Çalıştır (interaktif, soruları cevapla)
sudo ./setup-ubuntu-db-server.sh
```

**Script sana soracak:**
- API Server Private IP (örn: 10.0.0.1)
- Database adı (varsayılan: qiwi_gateway_prod)
- Database kullanıcı adı (varsayılan: qiwi_prod_user)
- Database şifresi (GÜÇ LÜ bir şifre!)
- Backup saklama süresi (gün, varsayılan: 30)

**Script yapacaklar:**
- ✅ PostgreSQL 15 kurulumu
- ✅ Database ve kullanıcı oluşturma
- ✅ Güvenlik ayarları (sadece API server erişimi)
- ✅ Firewall konfigürasyonu
- ✅ SSL bağlantı zorunluluğu
- ✅ Otomatik günlük backup (2 AM)
- ✅ Performance optimizasyonu

**Çıktı:** Connection string'i not et!

---

#### 2️⃣ API Server'ı Kur (Server 1)

```bash
# Server 1'e bağlan
ssh root@your-api-server-ip

# Script'i indir
wget https://raw.githubusercontent.com/IanaUlu/Payment_Gateway/main/setup-ubuntu-api-server.sh

# Çalıştırılabilir yap
chmod +x setup-ubuntu-api-server.sh

# Çalıştır (interaktif)
sudo ./setup-ubuntu-api-server.sh
```

**Script sana soracak:**
- Database Server Private IP (Server 2'nin IP'si)
- Database bilgileri (Server 2'de oluşturduğun)
- Domain adı (opsiyonel, örn: api.yourdomain.com)
- Email (SSL için, opsiyonel)
- GitHub repository URL

**Script yapacaklar:**
- ✅ Docker ve Docker Compose kurulumu
- ✅ Firewall konfigürasyonu (80, 443, 5000)
- ✅ Nginx reverse proxy kurulumu
- ✅ Application dizin yapısı oluşturma
- ✅ Git repository clone
- ✅ Docker container'ları build ve başlatma
- ✅ SSL sertifikası (Let's Encrypt, opsiyonel)
- ✅ Health check ve test

---

## 🔧 Detaylı Konfigürasyon

### Database Server (Server 2)

#### Güvenlik Özellikleri

```bash
# Sadece API server'dan erişim (pg_hba.conf)
hostssl qiwi_gateway_prod  qiwi_prod_user  10.0.0.1/32  scram-sha-256

# Diğer tüm erişimler engelli
host all all 0.0.0.0/0 reject
```

#### Firewall Kuralları

```bash
# UFW sadece API server'a izin verir
sudo ufw allow from 10.0.0.1 to any port 5432 proto tcp
```

#### Performance Ayarları

PostgreSQL production için optimize edilmiş:
- max_connections: 200
- shared_buffers: 256MB
- effective_cache_size: 1GB
- work_mem: 1MB

#### Backup Sistemi

```bash
# Günlük otomatik backup (02:00)
# Dosya: /var/backups/postgresql/qiwi_gateway_prod_YYYYMMDD_HHMMSS.sql.gz

# Manuel backup
sudo /usr/local/bin/pg-backup.sh

# Backup'ları listele
ls -lh /var/backups/postgresql/

# Backup'tan restore
gunzip -c backup_file.sql.gz | sudo -u postgres psql -d qiwi_gateway_prod
```

### API Server (Server 1)

#### Dizin Yapısı

```
/opt/qiwi-gateway/
├── app/                    # Git repository
├── logs/                   # Application logs
├── backups/                # (kullanılmıyor, DB server'da)
├── data/                   # Application data
├── nginx/
│   ├── nginx.conf         # Main nginx config
│   ├── conf.d/            # Site configs
│   └── ssl/               # SSL certificates
├── .env.production        # Environment variables
└── docker-compose.yml     # Docker configuration
```

#### Environment Variables (.env.production)

```bash
# Database (Remote Server)
POSTGRES_HOST=10.0.0.2
POSTGRES_PORT=5432
POSTGRES_DB=qiwi_gateway_prod
POSTGRES_USER=qiwi_prod_user
POSTGRES_PASSWORD=your_strong_password

# Application
ASPNETCORE_ENVIRONMENT=Production
TZ=Europe/Istanbul

# Security (otomatik generate edilir)
JWT_SECRET=random_256_bit_key
ENCRYPTION_KEY=random_256_bit_key
```

#### Docker Compose

API server sadece uygulama container'ını çalıştırır:

```yaml
services:
  api:
    # Remote database'e bağlanır
    environment:
      ConnectionStrings__DefaultConnection: "Host=${POSTGRES_HOST};Port=${POSTGRES_PORT};Database=${POSTGRES_DB};Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD};SSL Mode=Require"
  
  nginx:
    # Reverse proxy
    ports:
      - "80:80"
      - "443:443"
```

---

## 🌐 Domain ve SSL Kurulumu

### 1. DNS Ayarları

Domain'inizi API server'ın public IP'sine yönlendirin:

```
A Record: api.yourdomain.com → x.x.x.x (API Server Public IP)
```

### 2. SSL Sertifikası (Let's Encrypt)

Script otomatik yapacak ama manuel de yapabilirsin:

```bash
# Certbot kurulumu
sudo apt install certbot python3-certbot-nginx

# SSL sertifikası al
sudo certbot --nginx -d api.yourdomain.com

# Auto-renewal test
sudo certbot renew --dry-run
```

---

## 📊 Monitoring ve Bakım

### Logları İzleme

**API Server:**
```bash
# Application logs
cd /opt/qiwi-gateway
docker compose logs -f api

# Nginx logs
docker compose logs -f nginx

# Tüm loglar
tail -f logs/*.log
```

**Database Server:**
```bash
# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-*.log

# Backup logs
sudo tail -f /var/log/pg-backup.log

# Active connections
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity WHERE datname='qiwi_gateway_prod';"
```

### Health Checks

```bash
# API Server
curl http://localhost:5000/health
curl https://api.yourdomain.com/health

# Database Server
sudo -u postgres pg_isready
```

### Service Yönetimi

**API Server:**
```bash
cd /opt/qiwi-gateway

# Status
docker compose ps

# Restart
docker compose restart

# Stop
docker compose down

# Start
docker compose up -d

# Update (git pull + rebuild)
cd app && git pull && cd ..
docker compose up -d --build
```

**Database Server:**
```bash
# Status
sudo systemctl status postgresql

# Restart
sudo systemctl restart postgresql

# Logs
sudo journalctl -u postgresql -f
```

---

## 🔄 Deployment Workflow

### İlk Deployment

1. Database server'ı kur
2. API server'ı kur
3. DNS'i ayarla
4. SSL'i aktifleştir
5. Test et

### Güncelleme (Update)

```bash
# API Server'da
cd /opt/qiwi-gateway/app
git pull origin main
cd ..
docker compose up -d --build

# Zero-downtime için
docker compose up -d --no-deps --build api
```

### Database Migration

```bash
# API başlangıcında otomatik çalışır
# Program.cs içinde migration kodu var

# Manuel çalıştırmak için
docker exec -it qiwi_api_prod dotnet ef database update
```

---

## 🛡️ Güvenlik Best Practices

### Network Güvenliği

✅ **Yapılması Gerekenler:**
- Database server'ı private network'te tut
- API server firewall'u sadece 80, 443, 22'ye izin ver
- SSH key-based authentication kullan
- Root login'i devre dışı bırak

```bash
# SSH key-based auth
# Local'de key oluştur
ssh-keygen -t ed25519

# Server'a kopyala
ssh-copy-id root@server-ip

# Root login kapat
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
sudo systemctl restart sshd
```

### Database Güvenliği

✅ **Yapılması Gerekenler:**
- Güçlü şifreler (minimum 32 karakter)
- SSL zorunluluğu
- IP whitelist (sadece API server)
- Düzenli backup kontrolü

### Application Güvenliği

✅ **Yapılması Gerekenler:**
- Environment variables'ı güvenli tut
- Log rotation aktif
- Rate limiting (nginx seviyesinde)
- HTTPS zorunluluğu

---

## 🔧 Sorun Giderme

### API Database'e Bağlanamıyor

```bash
# 1. Database server'dan bağlantıyı test et
sudo -u postgres psql -d qiwi_gateway_prod -c "SELECT version();"

# 2. Firewall kontrolü
sudo ufw status

# 3. PostgreSQL dinliyor mu?
sudo netstat -tulpn | grep 5432

# 4. pg_hba.conf kontrolü
sudo cat /etc/postgresql/15/main/pg_hba.conf | grep qiwi

# 5. API server'dan test
# API server'da
telnet 10.0.0.2 5432
```

### SSL Hatası

```bash
# Certificate kontrolü
sudo certbot certificates

# Yenileme
sudo certbot renew

# Manuel yenileme
sudo certbot --nginx -d api.yourdomain.com --force-renewal
```

### Disk Doluyor

```bash
# Disk kullanımı
df -h

# Log rotation
# API Server
docker system prune -a

# Database Server
sudo find /var/backups/postgresql/ -name "*.sql.gz" -mtime +30 -delete
```

---

## 📈 Performans İyileştirme

### Database Tuning

```sql
-- Slow query log
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1 saniye
SELECT pg_reload_conf();

-- Index'leri kontrol et
SELECT schemaname, tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public';

-- Unused index'leri bul
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

### API Caching

Nginx seviyesinde caching ekle (isteğe bağlı).

---

## 💰 Maliyet Optimizasyonu

### Cloud Provider Önerileri

**Küçük/Orta Ölçek:**
- **DigitalOcean:** $24/ay (2 droplet: $12 each)
- **Hetzner:** €10/ay (çok uygun!)
- **Vultr:** $18/ay

**Büyük Ölçek:**
- **AWS EC2:** + RDS
- **Google Cloud:** Compute Engine + Cloud SQL

---

## 📞 Destek ve İletişim

Sorun yaşarsan:
1. Logları kontrol et
2. Health check'leri test et
3. GitHub Issues aç

---

**Son Güncelleme:** 2025-11-23

**Hazırlayan:** GitHub Copilot + IanaUlu Team
