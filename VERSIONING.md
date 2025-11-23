# Version Management & Git Tags

## ??? Current Version: 1.0.0

---

## Creating a New Version Tag

### Step 1: Update Version
Edit `VERSION.md` with new version details.

### Step 2: Commit Changes
```bash
git add .
git commit -m "Release v1.0.0: Initial production release"
```

### Step 3: Create Annotated Tag
```bash
# Create annotated tag with message
git tag -a v1.0.0 -m "Release v1.0.0

Features:
- QIWI Payment Gateway API
- Docker containerization
- PostgreSQL integration
- Comprehensive testing

See VERSION.md for full changelog"
```

### Step 4: Push Tag to Remote
```bash
# Push commits
git push origin main

# Push tag
git push origin v1.0.0

# Or push all tags
git push origin --tags
```

---

## Version Tag Commands

### List All Tags
```bash
git tag
git tag -l "v*"
```

### View Tag Details
```bash
git show v1.0.0
```

### Checkout Specific Version
```bash
git checkout v1.0.0
```

### Delete Tag (if needed)
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

---

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

**Format:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking changes (e.g., v2.0.0)
- **MINOR:** New features, backward compatible (e.g., v1.1.0)
- **PATCH:** Bug fixes (e.g., v1.0.1)

### Examples:

```bash
# Bug fix release
git tag -a v1.0.1 -m "Fix: Database connection timeout issue"

# New feature release
git tag -a v1.1.0 -m "Feature: Added Mobile payment provider"

# Breaking change release
git tag -a v2.0.0 -m "Breaking: Refactored API endpoints structure"
```

---

## Release Process Checklist

- [ ] Update `VERSION.md` with new version and changes
- [ ] Run tests: `dotnet test`
- [ ] Build Docker image: `docker-compose build`
- [ ] Test locally: `docker-compose up -d`
- [ ] Commit changes: `git commit -m "Release vX.Y.Z"`
- [ ] Create tag: `git tag -a vX.Y.Z -m "Release message"`
- [ ] Push commits: `git push origin main`
- [ ] Push tag: `git push origin vX.Y.Z`
- [ ] Create GitHub Release (optional)
- [ ] Update deployment on server

---

## GitHub Releases

After pushing a tag, you can create a GitHub Release:

1. Go to: https://github.com/IanaUlu/Payment-Gateway/releases
2. Click "Create a new release"
3. Select your tag (e.g., v1.0.0)
4. Add release title and description
5. Attach binaries if needed
6. Click "Publish release"

---

## Version Branches Strategy

### Main Branch
- **main** - Production-ready code
- Always stable
- Only merge tested features

### Feature Branches
```bash
git checkout -b feature/mobile-provider
# ... work on feature ...
git commit -m "Add mobile provider support"
git push origin feature/mobile-provider
# Create Pull Request to main
```

### Hotfix Branches
```bash
git checkout -b hotfix/1.0.1-database-timeout
# ... fix bug ...
git commit -m "Fix database timeout in production"
git push origin hotfix/1.0.1-database-timeout
# Create Pull Request to main
```

---

## Rollback to Previous Version

```bash
# View available versions
git tag

# Rollback to specific version
git checkout v1.0.0

# Or reset to previous version (CAREFUL!)
git reset --hard v1.0.0
git push --force origin main  # Only if absolutely necessary!
```

---

## Quick Commands Reference

```bash
# Create new release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# List tags
git tag -l

# View tag details
git show v1.0.0

# Delete tag
git tag -d v1.0.0
git push origin --delete v1.0.0

# Checkout version
git checkout v1.0.0
```

---

**Always test before tagging a release!** ?
