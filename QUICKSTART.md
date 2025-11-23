# ?? Quick Start - Deploy to Ubuntu Server

## ?? What you need:
- Ubuntu 14.04 server (64-bit)
- Root access
- Internet connection

---

## ? 3 Simple Steps

### Step 1??: Install Docker (on server)

```bash
# Download and run installation script
wget https://get.docker.com -O get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

---

### Step 2??: Upload your code

**Option A: Using Git (recommended)**
```bash
sudo apt-get install -y git
git clone https://github.com/IanaUlu/MyTestApp.git
cd MyTestApp
```

**Option B: Using SCP (from your PC)**
```bash
# On your PC (Windows)
# Zip your project first, then:
scp QiwiGateway.zip user@server_ip:/home/user/
ssh user@server_ip
unzip QiwiGateway.zip
cd QiwiGateway
```

---

### Step 3??: Deploy!

```bash
# Just run this command:
docker-compose up -d

# Wait 30 seconds for database to initialize...

# Check if everything is running:
docker-compose ps
```

---

## ? Test your API

```bash
# Health check
curl http://localhost:5000/health

# Test payment check
curl "http://localhost:5000/payment_app.cgi?command=check&txn_id=TEST&account=123456&sum=100&prv_id=100001"
```

**Success!** You should see XML response:
```xml
<response>
  <osmp_txn_id>TEST</osmp_txn_id>
  <result>0</result>
  <comment>TestProtocol: check for account 123456</comment>
</response>
```

---

## ?? Access from outside

From your PC or QIWI:
```
http://YOUR_SERVER_IP:5000/payment_app.cgi
```

Example:
```
http://192.168.1.100:5000/payment_app.cgi?command=check&txn_id=T001&account=123456&sum=100&prv_id=100001
```

---

## ?? Useful Commands

| What | Command |
|------|---------|
| **View logs** | `docker-compose logs -f` |
| **Stop** | `docker-compose stop` |
| **Start** | `docker-compose start` |
| **Restart** | `docker-compose restart` |
| **Update code** | `git pull && docker-compose up -d --build` |
| **View API logs** | `docker-compose logs -f qiwi_api` |
| **View DB** | `docker-compose exec postgres psql -U bePay_user -d qiwi_gateway` |

---

## ?? If something goes wrong

```bash
# Check what's running
docker-compose ps

# See all logs
docker-compose logs

# Restart everything
docker-compose restart

# Complete reset (WARNING: deletes database!)
docker-compose down -v
docker-compose up -d
```

---

## ?? Project Structure

```
QiwiGateway/
??? docker-compose.yml    # Docker configuration
??? Dockerfile            # How to build your app
??? deploy.sh            # Deployment script
??? DEPLOYMENT.md        # Full guide
??? QiwiGateway.Api/     # Your application
```

---

## ?? Security Tips

1. **Change default password** in `docker-compose.yml`:
   ```yaml
   POSTGRES_PASSWORD: YOUR_STRONG_PASSWORD_HERE
   ```

2. **Allow only QIWI IP** (if you know it):
   ```bash
   sudo ufw allow from QIWI_IP to any port 5000
   sudo ufw enable
   ```

3. **Check logs regularly**:
   ```bash
   docker-compose logs -f | grep ERROR
   ```

---

## ?? Need Help?

1. Read full guide: `cat DEPLOYMENT.md`
2. Check logs: `docker-compose logs -f`
3. GitHub Issues: https://github.com/IanaUlu/MyTestApp/issues

---

**That's it! You're live! ??**

For detailed documentation, see `DEPLOYMENT.md`
