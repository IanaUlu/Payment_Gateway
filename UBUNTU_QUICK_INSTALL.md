# Ubuntu Server Hızlı Kurulum

## Yöntem 1: Git Clone (Önerilen)

```bash
# Git kurulumu
sudo apt update
sudo apt install -y git

# Repository clone
git clone https://github.com/IanaUlu/Payment_Gateway.git
cd Payment_Gateway

# Script izinlerini ayarla
chmod +x setup-ubuntu-db-server.sh
chmod +x setup-ubuntu-api-server.sh

# DB Server için
sudo ./setup-ubuntu-db-server.sh

# API Server için
sudo ./setup-ubuntu-api-server.sh
```

## Yöntem 2: Manuel Script İndirme

Eğer 404 hatası alıyorsan:

```bash
# 1. Önce repository'i kontrol et
curl -I https://api.github.com/repos/IanaUlu/Payment_Gateway/contents/setup-ubuntu-db-server.sh

# 2. GitHub raw yerine git clone kullan
git clone https://github.com/IanaUlu/Payment_Gateway.git
cd Payment_Gateway
ls -la setup-ubuntu-*.sh
```

## Yöntem 3: SCP ile Dosya Transferi

Windows'tan Ubuntu'ya doğrudan kopyala:

```powershell
# PowerShell'den (Windows)
scp setup-ubuntu-db-server.sh user@192.168.1.10:/home/user/
scp setup-ubuntu-api-server.sh user@192.168.1.11:/home/user/
```

## Sorun Giderme

### 404 Hatası Alıyorsan:

1. **Repository public mi kontrol et:**
   - https://github.com/IanaUlu/Payment_Gateway
   - Repo ayarları → Visibility → Public olmalı

2. **Branch'i kontrol et:**
   ```bash
   # GitHub'da main branch'te mi?
   curl https://api.github.com/repos/IanaUlu/Payment_Gateway/branches
   ```

3. **Raw URL yerine git clone kullan:**
   - wget/curl ile raw dosya indirme yerine
   - git clone ile tüm repo'yu indir

### Private Repository İse:

```bash
# 1. SSH key oluştur Ubuntu'da
ssh-keygen -t ed25519 -C "server@qiwi.local"

# 2. Public key'i kopyala
cat ~/.ssh/id_ed25519.pub

# 3. GitHub → Settings → SSH Keys → Add SSH key

# 4. SSH ile clone et
git clone git@github.com:IanaUlu/Payment_Gateway.git
```

## Kurulum Sonrası Kontrol

```bash
# API Server'da
docker ps
curl http://localhost:5000/health

# DB Server'da
sudo systemctl status postgresql
sudo -u postgres psql -c "SELECT version();"
```

## Test Environment (Port 5001/5434)

```bash
# API Test Server
cd Payment_Gateway
docker-compose -f docker-compose.test.yml up -d
curl http://localhost:5001/health

# DB Test Server
sudo -u postgres psql -d qiwi_gateway_test -c "SELECT current_database();"
```

## Production Environment (Port 5000/5433)

```bash
# API Prod Server
cd Payment_Gateway
docker-compose -f docker-compose.production.yml up -d
curl http://localhost:5000/health

# DB Prod Server
sudo -u postgres psql -d qiwi_gateway_prod -c "SELECT current_database();"
```

## Firewall IP Whitelist

```bash
# ESXi network'ten erişim için
sudo ufw allow from 192.168.1.0/24 to any port 5000
sudo ufw allow from 192.168.1.0/24 to any port 5432

# Belirli IP'lerden
sudo ufw allow from 203.0.113.10 to any port 5000
sudo ufw allow from 203.0.113.20 to any port 5000
```
