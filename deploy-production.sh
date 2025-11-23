#!/bin/bash
# Deploy to PRODUCTION Environment
# Usage: ./deploy-production.sh

set -e  # Exit on error

echo "======================================"
echo "  🚀 DEPLOYING TO PRODUCTION"
echo "======================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BRANCH="main"
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env.production"
BACKUP_DIR="./backups"

# Production deployment confirmation
echo -e "${RED}⚠️  WARNING: You are about to deploy to PRODUCTION!${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo -e "${YELLOW}📋 Pre-deployment checks...${NC}"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    exit 1
fi

# Check if on correct branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo -e "${RED}❌ Must be on ${BRANCH} branch (currently on ${CURRENT_BRANCH})${NC}"
    exit 1
fi

# Check if git repo is clean
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}❌ You have uncommitted changes. Commit them first!${NC}"
    exit 1
fi

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ $ENV_FILE not found!${NC}"
    echo "Create it with: cp .env.production.example $ENV_FILE"
    exit 1
fi

echo -e "${GREEN}✓ Pre-checks passed${NC}"

# Pull latest code from main branch
echo -e "${YELLOW}📥 Pulling latest code from ${BRANCH}...${NC}"
git fetch origin
git pull origin $BRANCH

COMMIT_HASH=$(git rev-parse --short HEAD)
echo -e "${BLUE}Deploying commit: ${COMMIT_HASH}${NC}"

echo -e "${GREEN}✓ Code updated${NC}"

# Load production environment variables
echo -e "${YELLOW}🔧 Loading production environment variables...${NC}"
export $(cat $ENV_FILE | grep -v '^#' | xargs)
echo -e "${GREEN}✓ Environment loaded${NC}"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
echo -e "${YELLOW}💾 Creating database backup...${NC}"
BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"

if docker ps | grep -q "qiwi_postgres_prod"; then
    docker exec qiwi_postgres_prod pg_dump -U ${POSTGRES_USER:-qiwi_prod_user} qiwi_gateway_prod > $BACKUP_FILE
    echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  No running database to backup${NC}"
fi

# Stop existing containers (gracefully)
echo -e "${YELLOW}🛑 Stopping existing production containers...${NC}"
docker-compose -f $COMPOSE_FILE down --timeout 30

# Build new images
echo -e "${YELLOW}🏗️  Building production images...${NC}"
docker-compose -f $COMPOSE_FILE build --no-cache

# Start containers
echo -e "${YELLOW}🚀 Starting production environment...${NC}"
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be healthy (this may take a minute)...${NC}"
sleep 15

# Check container status
MAX_RETRIES=6
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
        echo -e "${GREEN}✓ Containers are running${NC}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT+1))
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo -e "${RED}❌ Containers failed to start${NC}"
            docker-compose -f $COMPOSE_FILE logs --tail=50
            
            # Rollback
            echo -e "${YELLOW}🔄 Rolling back...${NC}"
            docker-compose -f $COMPOSE_FILE down
            
            # Restore backup if exists
            if [ -f "$BACKUP_FILE" ]; then
                echo -e "${YELLOW}Restoring database backup...${NC}"
                docker-compose -f $COMPOSE_FILE up -d postgres
                sleep 10
                cat $BACKUP_FILE | docker exec -i qiwi_postgres_prod psql -U ${POSTGRES_USER:-qiwi_prod_user} qiwi_gateway_prod
            fi
            
            exit 1
        fi
        echo -e "${YELLOW}Retry $RETRY_COUNT/$MAX_RETRIES...${NC}"
        sleep 10
    fi
done

# Health check
echo -e "${YELLOW}🏥 Running health checks...${NC}"
sleep 5

MAX_HEALTH_RETRIES=5
HEALTH_RETRY_COUNT=0
while [ $HEALTH_RETRY_COUNT -lt $MAX_HEALTH_RETRIES ]; do
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✓ API health check passed${NC}"
        break
    else
        HEALTH_RETRY_COUNT=$((HEALTH_RETRY_COUNT+1))
        if [ $HEALTH_RETRY_COUNT -eq $MAX_HEALTH_RETRIES ]; then
            echo -e "${RED}❌ API health check failed${NC}"
            docker-compose -f $COMPOSE_FILE logs api --tail=50
            exit 1
        fi
        echo -e "${YELLOW}Health check retry $HEALTH_RETRY_COUNT/$MAX_HEALTH_RETRIES...${NC}"
        sleep 10
    fi
done

# Cleanup old images
echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
docker image prune -f

# Show running containers
echo ""
echo -e "${GREEN}======================================"
echo "  ✅ PRODUCTION DEPLOYMENT SUCCESSFUL"
echo "======================================${NC}"
echo ""
echo "📊 Deployment Info:"
echo "  Commit:    $COMMIT_HASH"
echo "  Time:      $(date)"
echo "  Backup:    $BACKUP_FILE"
echo ""
echo "📊 Container Status:"
docker-compose -f $COMPOSE_FILE ps
echo ""
echo "🌐 Production API: http://localhost:5000"
echo "🗄️  Database: localhost:5433 (localhost only)"
echo ""
echo "📋 Useful commands:"
echo "  View logs:    docker-compose -f $COMPOSE_FILE logs -f"
echo "  Stop:         docker-compose -f $COMPOSE_FILE down"
echo "  Restart:      docker-compose -f $COMPOSE_FILE restart"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "  1. Monitor logs for errors"
echo "  2. Run smoke tests"
echo "  3. Update monitoring/alerting"
echo ""
