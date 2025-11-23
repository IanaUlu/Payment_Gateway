# Git Commands for Deployment

## ?? Push to GitHub

```bash
# Check status
git status

# Add all Docker files
git add Dockerfile docker-compose.yml .dockerignore
git add deploy.sh install-docker.sh test-docker.ps1
git add DEPLOYMENT.md QUICKSTART.md CHECKLIST.md
git add QiwiGateway.Api/appsettings.Production.json

# Commit
git commit -m "Add Docker deployment configuration"

# Push to GitHub
git push origin main
```

---

## ??? On Server (after push)

```bash
# Clone (first time)
git clone https://github.com/IanaUlu/MyTestApp.git
cd MyTestApp

# Or update (if already cloned)
cd MyTestApp
git pull

# Deploy
docker-compose up -d
```

---

## ?? Update Workflow

### On your PC (Windows):
```bash
# Make changes to code
# Test locally
dotnet build
dotnet test

# Commit and push
git add .
git commit -m "Your change description"
git push
```

### On Server:
```bash
cd MyTestApp
git pull
docker-compose up -d --build
```

---

That's it! ?
