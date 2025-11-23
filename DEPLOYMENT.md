# QiwiGateway Deployment Guide ??

## ?? Prerequisites

- Ubuntu 14.04 (64-bit)
- Root or sudo access
- At least 2GB RAM
- 10GB free disk space

---

## ?? Step 1: Install Docker

### On the server, run:

```bash
# Download installation script
wget https://raw.githubusercontent.com/IanaUlu/MyTestApp/main/install-docker.sh

# Make it executable
chmod +x install-docker.sh

# Run installation (requires sudo)
sudo bash install-docker.sh

# Logout and login again for docker group to take effect
exit
```

### Verify Docker installation:

```bash
docker --version
docker-compose --version
```

---

## ?? Step 2: Clone Repository

```bash
# Install git if not installed
sudo apt-get update
sudo apt-get install -y git

# Clone repository
git clone https://github.com/IanaUlu/MyTestApp.git
cd MyTestApp
```

---

## ?? Step 3: Deploy Application

### Option A: Using deploy script (Recommended)

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run deployment
bash deploy.sh
```

### Option B: Manual deployment

```bash
# Build and start containers
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

---

## ?? Step 4: Verify Deployment

### Check health:

```bash
curl http://localhost:5000/health
```

Expected response:
```json
{"status":"healthy","timestamp":"2024-11-23T..."}
```

### Test API:

```bash
curl "http://localhost:5000/payment_app.cgi?command=check&txn_id=TEST001&account=123456&sum=100&prv_id=100001"
```

Expected response (XML):
```xml
<response>
  <osmp_txn_id>TEST001</osmp_txn_id>
  <result>0</result>
  <comment>TestProtocol: check for account 123456</comment>
</response>
```

---

## ?? Useful Commands

### View logs:
```bash
# All logs
docker-compose logs -f

# Only API logs
docker-compose logs -f qiwi_api

# Only PostgreSQL logs
docker-compose logs -f postgres
```

### Restart services:
```bash
# Restart all
docker-compose restart

# Restart only API
docker-compose restart qiwi_api
```

### Stop services:
```bash
docker-compose stop
```

### Start services:
```bash
docker-compose start
```

### Remove all (including volumes):
```bash
docker-compose down -v
```

### View API logs inside container:
```bash
docker-compose exec qiwi_api cat /app/Logs/log_$(date +%Y-%m-%d).txt
```

### Access PostgreSQL:
```bash
docker-compose exec postgres psql -U bePay_user -d qiwi_gateway
```

### Check database tables:
```sql
\dt
SELECT * FROM "Transactions" LIMIT 10;
```

---

## ?? Configuration

### Environment variables (docker-compose.yml):

```yaml
environment:
  - ASPNETCORE_ENVIRONMENT=Production
  - ConnectionStrings__DefaultConnection=Host=postgres;Port=5432;Database=qiwi_gateway;Username=bePay_user;Password=YOUR_PASSWORD
  - TZ=Asia/Tbilisi  # Your timezone
```

### Ports:

- **API**: 5000 (mapped to host:5000)
- **PostgreSQL**: 5432 (mapped to host:5432)

### Change ports (if needed):

Edit `docker-compose.yml`:
```yaml
ports:
  - "8080:5000"  # External:Internal
```

---

## ?? Security Recommendations

### 1. Change default password:

Edit `docker-compose.yml` and `appsettings.json`:
```
POSTGRES_PASSWORD: YOUR_STRONG_PASSWORD
```

### 2. Close PostgreSQL port (if not needed externally):

Remove from `docker-compose.yml`:
```yaml
# ports:
#   - "5432:5432"
```

### 3. Setup firewall:

```bash
# Allow only specific IP to access API
sudo ufw allow from YOUR_QIWI_IP to any port 5000
sudo ufw enable
```

### 4. Use reverse proxy (Nginx):

See `NGINX.md` for configuration.

---

## ?? Updating Application

### Pull latest changes and rebuild:

```bash
cd MyTestApp
git pull
bash deploy.sh
```

Or manually:
```bash
git pull
docker-compose down
docker-compose up -d --build
```

---

## ?? Troubleshooting

### Container won't start:

```bash
# Check logs
docker-compose logs qiwi_api

# Check if port is already in use
sudo netstat -tulpn | grep 5000

# Remove old containers
docker-compose down
docker system prune -a
```

### Database connection error:

```bash
# Check if PostgreSQL is healthy
docker-compose ps

# Restart PostgreSQL
docker-compose restart postgres

# Wait for it to be ready
sleep 10
docker-compose restart qiwi_api
```

### API returns 502:

```bash
# Check if API is running
docker-compose ps

# Check API logs
docker-compose logs qiwi_api

# Restart API
docker-compose restart qiwi_api
```

### Logs directory permission denied:

```bash
# Fix permissions
sudo chown -R $(whoami):$(whoami) ./logs
```

---

## ?? Monitoring

### Resource usage:

```bash
docker stats
```

### Disk usage:

```bash
docker system df
```

### Clean up unused data:

```bash
docker system prune -a --volumes
```

---

## ?? Backup & Restore

### Backup database:

```bash
# Create backup
docker-compose exec postgres pg_dump -U bePay_user qiwi_gateway > backup_$(date +%Y%m%d).sql

# Or with docker
docker-compose exec -T postgres pg_dump -U bePay_user qiwi_gateway | gzip > backup_$(date +%Y%m%d).sql.gz
```

### Restore database:

```bash
# Restore from backup
docker-compose exec -T postgres psql -U bePay_user qiwi_gateway < backup_20241123.sql

# Or from gzip
gunzip -c backup_20241123.sql.gz | docker-compose exec -T postgres psql -U bePay_user qiwi_gateway
```

---

## ?? Support

If you encounter issues:

1. Check logs: `docker-compose logs -f`
2. Verify health: `curl http://localhost:5000/health`
3. Check GitHub Issues: https://github.com/IanaUlu/MyTestApp/issues

---

## ?? Quick Reference

| Task | Command |
|------|---------|
| Start | `docker-compose up -d` |
| Stop | `docker-compose stop` |
| Restart | `docker-compose restart` |
| Logs | `docker-compose logs -f` |
| Status | `docker-compose ps` |
| Update | `git pull && bash deploy.sh` |
| Backup DB | `docker-compose exec postgres pg_dump -U bePay_user qiwi_gateway > backup.sql` |

---

**Good luck! ??**
