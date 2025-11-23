# ?? Deployment Checklist

## ? Before Deployment

- [ ] Code is tested locally
- [ ] All unit tests pass: `dotnet test --filter "FullyQualifiedName~UnitTests"`
- [ ] Database connection string is correct
- [ ] Changed default password in `docker-compose.yml`
- [ ] Git repository is up to date: `git push`

---

## ?? On Server

### 1. Install Docker
```bash
wget https://get.docker.com -O get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Clone Repository
```bash
sudo apt-get install -y git
git clone https://github.com/IanaUlu/MyTestApp.git
cd MyTestApp
```

### 3. Deploy
```bash
docker-compose up -d
```

### 4. Verify
```bash
# Wait 30 seconds, then:
docker-compose ps
curl http://localhost:5000/health
```

---

## ?? After Deployment

- [ ] Health check returns OK
- [ ] Test API with CHECK command
- [ ] Test API with PAY command
- [ ] Check logs: `docker-compose logs -f`
- [ ] Verify database: `docker-compose exec postgres psql -U bePay_user -d qiwi_gateway`
- [ ] Configure firewall if needed
- [ ] Provide QIWI with server IP and port

---

## ?? Server Info for QIWI

**Endpoint URL:**
```
http://YOUR_SERVER_IP:5000/payment_app.cgi
```

**Provider ID (Test):**
```
100001
```

**Test Account:**
```
123456
```

**Test Commands:**

Check:
```
http://YOUR_IP:5000/payment_app.cgi?command=check&txn_id=T001&account=123456&sum=100&prv_id=100001
```

Pay:
```
http://YOUR_IP:5000/payment_app.cgi?command=pay&txn_id=T002&account=123456&sum=150&prv_id=100001
```

---

## ?? Troubleshooting

| Problem | Solution |
|---------|----------|
| Container won't start | `docker-compose logs qiwi_api` |
| Database error | `docker-compose restart postgres && sleep 10 && docker-compose restart qiwi_api` |
| Port already in use | Change port in `docker-compose.yml` |
| Permission denied | `sudo chown -R $USER:$USER .` |

---

## ?? Support Contacts

- GitHub: https://github.com/IanaUlu/MyTestApp
- Logs location: `./logs/`
- Database backup: `docker-compose exec postgres pg_dump -U bePay_user qiwi_gateway > backup.sql`

---

**Good luck! ??**
