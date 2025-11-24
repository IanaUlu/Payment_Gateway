# QIWI Gateway - Quick Setup Guide for VMs
# This guide helps you setup 4 Ubuntu VMs (Test & Production environments)

## 📋 VM Setup Quick Reference

### Required VMs:

| VM Name       | Purpose     | Specs              | Private IP    | Public IP   |
|---------------|-------------|--------------------|---------------|-------------|
| QIWI-API-Test | API Test    | 2 CPU, 2GB, 20GB  | 192.168.56.101| Dynamic     |
| QIWI-DB-Test  | DB Test     | 2 CPU, 4GB, 50GB  | 192.168.56.102| -           |
| QIWI-API-Prod | API Prod    | 4 CPU, 4GB, 20GB  | 192.168.56.103| Your Domain |
| QIWI-DB-Prod  | DB Prod     | 4 CPU, 8GB, 100GB | 192.168.56.104| -           |

---

## 🖥️ Method 1: VirtualBox (Free, Local)

### Step 1: Download & Install VirtualBox

**Windows (PowerShell):**
```powershell
# Using Chocolatey
choco install virtualbox -y

# Or download from: https://www.virtualbox.org/
```

**Ubuntu Server ISO:**
```powershell
# Download Ubuntu 22.04 LTS
$url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso"
Invoke-WebRequest -Uri $url -OutFile "$env:USERPROFILE\Downloads\ubuntu-22.04-server.iso"
```

### Step 2: Create VMs

For each VM, use VirtualBox GUI:

```
1. Click "New"
2. Name: QIWI-API-Test (or DB-Test, API-Prod, DB-Prod)
3. Type: Linux
4. Version: Ubuntu (64-bit)
5. Memory: 
   - API: 2048 MB
   - DB: 4096-8192 MB
6. Create virtual hard disk: VDI, Dynamically allocated
   - API: 20 GB
   - DB: 50-100 GB
7. Settings → Storage → Add ISO file
8. Settings → Network:
   - Adapter 1: NAT (for internet)
   - Adapter 2: Host-Only Network (192.168.56.0/24)
9. Start VM
```

### Step 3: Install Ubuntu Server

When VM boots:

```
Language: English
Update installer: (Skip if prompted)
Keyboard: English (US)
Network connections:
  - enp0s3 (NAT): DHCPv4
  - enp0s8 (Host-Only): Edit IPv4
    * Manual
    * Subnet: 192.168.56.0/24
    * Address: 192.168.56.101 (or .102, .103, .104)
    * Gateway: 192.168.56.1
    * DNS: 8.8.8.8
Mirror: (default)
Storage: Use entire disk
Profile:
  - Your name: qiwi
  - Server name: api-test (or db-test, api-prod, db-prod)
  - Username: qiwi
  - Password: [your secure password]
SSH: [X] Install OpenSSH server
Snaps: (none)
```

Click "Done" and wait for installation. Reboot when finished.

### Step 4: Connect via SSH from Windows

```powershell
# From Windows PowerShell or Terminal

# API-Test
ssh qiwi@192.168.56.101

# DB-Test
ssh qiwi@192.168.56.102

# API-Prod
ssh qiwi@192.168.56.103

# DB-Prod
ssh qiwi@192.168.56.104
```

### Step 5: Run Setup Scripts

**On DB-Test (192.168.56.102):**
```bash
sudo apt update && sudo apt upgrade -y
wget https://raw.githubusercontent.com/IanaUlu/Payment_Gateway/develop/setup-ubuntu-db-server.sh
chmod +x setup-ubuntu-db-server.sh
sudo ./setup-ubuntu-db-server.sh

# When prompted:
# API Server IP: 192.168.56.101
# Database Name: qiwi_gateway_test
# Database User: qiwi_test_user
# Database Password: [strong password - SAVE IT!]
# Backup Retention: 7
```

**On API-Test (192.168.56.101):**
```bash
sudo apt update && sudo apt upgrade -y
wget https://raw.githubusercontent.com/IanaUlu/Payment_Gateway/develop/setup-ubuntu-api-server.sh
chmod +x setup-ubuntu-api-server.sh
sudo ./setup-ubuntu-api-server.sh

# When prompted:
# Database Server IP: 192.168.56.102
# Database Name: qiwi_gateway_test
# Database User: qiwi_test_user
# Database Password: [same as DB-Test]
# Domain: (leave empty)
# Email: (leave empty)
# GitHub Repo: https://github.com/IanaUlu/Payment_Gateway.git

# After installation, switch to develop branch:
cd /opt/qiwi-gateway/app
git checkout develop
git pull origin develop
cd ..
docker compose up -d --build
```

**On DB-Prod (192.168.56.104):**
```bash
sudo apt update && sudo apt upgrade -y
wget https://raw.githubusercontent.com/IanaUlu/Payment_Gateway/develop/setup-ubuntu-db-server.sh
chmod +x setup-ubuntu-db-server.sh
sudo ./setup-ubuntu-db-server.sh

# When prompted:
# API Server IP: 192.168.56.103
# Database Name: qiwi_gateway_prod
# Database User: qiwi_prod_user
# Database Password: [VERY STRONG password - SAVE IT!]
# Backup Retention: 30
```

**On API-Prod (192.168.56.103):**
```bash
sudo apt update && sudo apt upgrade -y
wget https://raw.githubusercontent.com/IanaUlu/Payment_Gateway/develop/setup-ubuntu-api-server.sh
chmod +x setup-ubuntu-api-server.sh
sudo ./setup-ubuntu-api-server.sh

# When prompted:
# Database Server IP: 192.168.56.104
# Database Name: qiwi_gateway_prod
# Database User: qiwi_prod_user
# Database Password: [same as DB-Prod]
# Domain: api.yourdomain.com (or leave empty)
# Email: admin@yourdomain.com (or leave empty)
# GitHub Repo: https://github.com/IanaUlu/Payment_Gateway.git

# After installation, ensure on main branch:
cd /opt/qiwi-gateway/app
git checkout main
git pull origin main
cd ..
docker compose up -d --build
```

### Step 6: Test Connectivity

**From Windows:**
```powershell
# Test API-Test
curl http://192.168.56.101:5001/health

# Test API-Prod
curl http://192.168.56.103:5000/health
```

---

## ☁️ Method 2: Cloud Providers (Recommended for Production)

### Option A: Hetzner Cloud (Cheapest - €15-20/month)

1. **Sign up:** https://www.hetzner.com/cloud
2. **Create Project:** "QIWI Gateway"
3. **Create Private Networks:**
   - Test Network: 10.0.1.0/24
   - Prod Network: 10.0.2.0/24

4. **Create Servers:**

**DB-Test:**
```
Location: Falkenstein, Germany
Image: Ubuntu 22.04
Type: CPX11 (2 vCPU, 2GB RAM, 40GB SSD) - €4.51/month
Networks: Test Network
SSH Key: Add your public key
```

**API-Test:**
```
Type: CPX11 (2 vCPU, 2GB RAM, 40GB SSD) - €4.51/month
Networks: Test Network
Firewall: Create (allow 22, 80, 443, 5001)
```

**DB-Prod:**
```
Type: CPX21 (3 vCPU, 4GB RAM, 80GB SSD) - €8.21/month
Networks: Prod Network
```

**API-Prod:**
```
Type: CPX11 (2 vCPU, 2GB RAM, 40GB SSD) - €4.51/month
Networks: Prod Network
Firewall: Create (allow 22, 80, 443)
```

5. **Note Private IPs:**
```
DB-Test:  10.0.1.2
API-Test: 10.0.1.1
DB-Prod:  10.0.2.2
API-Prod: 10.0.2.1
```

6. **Run setup scripts** (same as VirtualBox method above, but use private IPs)

### Option B: DigitalOcean ($24-36/month)

1. **Sign up:** https://www.digitalocean.com/
2. **Create VPC Networks:**
   - Test VPC: 10.0.1.0/24
   - Prod VPC: 10.0.2.0/24

3. **Create Droplets:**

```
DB-Test:  Basic ($12/mo) - 2 vCPU, 2GB, 60GB
API-Test: Basic ($12/mo) - 2 vCPU, 2GB, 60GB
DB-Prod:  Basic ($18/mo) - 2 vCPU, 4GB, 80GB
API-Prod: Basic ($12/mo) - 2 vCPU, 2GB, 60GB
```

4. **Run setup scripts** (same as above)

---

## 🔥 Quick Commands Reference

### Connect to VMs:
```bash
ssh qiwi@192.168.56.101  # API-Test
ssh qiwi@192.168.56.102  # DB-Test
ssh qiwi@192.168.56.103  # API-Prod
ssh qiwi@192.168.56.104  # DB-Prod
```

### Check Status:
```bash
# On API servers
cd /opt/qiwi-gateway
docker compose ps
docker compose logs -f api

# On DB servers
sudo systemctl status postgresql
sudo -u postgres psql -c "\l"
```

### Update Application:
```bash
# Test (API-Test VM)
cd /opt/qiwi-gateway/app
git pull origin develop
cd ..
docker compose up -d --build

# Prod (API-Prod VM)
cd /opt/qiwi-gateway/app
git pull origin main
cd ..
docker compose up -d --build
```

---

## 📝 Post-Installation Checklist

**Test Environment:**
- [ ] DB-Test VM created and Ubuntu installed
- [ ] API-Test VM created and Ubuntu installed
- [ ] DB-Test setup script completed
- [ ] API-Test setup script completed
- [ ] Can access http://192.168.56.101:5001/health
- [ ] Can access http://192.168.56.101:5001/swagger
- [ ] Database connection working

**Production Environment:**
- [ ] DB-Prod VM created and Ubuntu installed
- [ ] API-Prod VM created and Ubuntu installed
- [ ] DB-Prod setup script completed
- [ ] API-Prod setup script completed
- [ ] SSL certificate configured (if using domain)
- [ ] Can access https://api.yourdomain.com/health
- [ ] Database connection working
- [ ] Backups configured and tested

**Security:**
- [ ] SSH key-based authentication enabled
- [ ] Firewall rules configured
- [ ] Database servers only accessible from API servers
- [ ] Strong passwords used everywhere
- [ ] Credentials saved securely

---

## 🆘 Troubleshooting

### Can't SSH to VM:
```bash
# Check if SSH service is running
sudo systemctl status ssh
sudo systemctl start ssh

# Check firewall
sudo ufw status
sudo ufw allow 22/tcp
```

### VM has no internet:
```bash
# Check network
ip addr show
ping google.com

# If NAT adapter not working, check VirtualBox network settings
```

### Script fails:
```bash
# Check logs
tail -f /var/log/syslog

# Try manual steps from the script
```

---

## 💡 Tips

1. **Snapshot VMs** after successful installation (VirtualBox: Machine → Take Snapshot)
2. **Use SSH keys** instead of passwords for better security
3. **Keep VMs updated:** `sudo apt update && sudo apt upgrade -y`
4. **Monitor resources:** `htop` on each VM
5. **Test backups regularly**

---

## 🎯 Next Steps After Setup

1. Configure your firewall whitelist IPs
2. Setup monitoring (optional)
3. Test the deployment workflow
4. Configure CI/CD (optional)

---

**Need help?** Check the logs or open a GitHub issue!
