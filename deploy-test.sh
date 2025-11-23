#!/bin/bash
# Deploy to TEST Environment
# Usage: ./deploy-test.sh

set -e  # Exit on error

echo "======================================"
echo "  🧪 DEPLOYING TO TEST ENVIRONMENT"
echo "======================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BRANCH="develop"
COMPOSE_FILE="docker-compose.test.yml"
ENV_FILE=".env.test"

echo -e "${YELLOW}📋 Pre-deployment checks...${NC}"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    exit 1
fi

# Check if git repo is clean
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ Pre-checks passed${NC}"

# Pull latest code from develop branch
echo -e "${YELLOW}📥 Pulling latest code from ${BRANCH}...${NC}"
git fetch origin
git checkout $BRANCH
git pull origin $BRANCH

echo -e "${GREEN}✓ Code updated${NC}"

# Load test environment variables
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}🔧 Loading test environment variables...${NC}"
    export $(cat $ENV_FILE | grep -v '^#' | xargs)
    echo -e "${GREEN}✓ Environment loaded${NC}"
else
    echo -e "${YELLOW}⚠️  $ENV_FILE not found, using defaults${NC}"
fi

# Stop existing containers
echo -e "${YELLOW}🛑 Stopping existing test containers...${NC}"
docker-compose -f $COMPOSE_FILE down

# Build new images
echo -e "${YELLOW}🏗️  Building new images...${NC}"
docker-compose -f $COMPOSE_FILE build --no-cache

# Start containers
echo -e "${YELLOW}🚀 Starting test environment...${NC}"
docker-compose -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo -e "${YELLOW}⏳ Waiting for services to be healthy...${NC}"
sleep 10

# Check container status
if docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Containers are running${NC}"
else
    echo -e "${RED}❌ Some containers failed to start${NC}"
    docker-compose -f $COMPOSE_FILE logs --tail=50
    exit 1
fi

# Health check
echo -e "${YELLOW}🏥 Running health checks...${NC}"
sleep 5

if curl -f http://localhost:5001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API health check passed${NC}"
else
    echo -e "${RED}❌ API health check failed${NC}"
    docker-compose -f $COMPOSE_FILE logs api_test --tail=50
    exit 1
fi

# Show running containers
echo ""
echo -e "${GREEN}======================================"
echo "  ✅ TEST DEPLOYMENT SUCCESSFUL"
echo "======================================${NC}"
echo ""
echo "📊 Container Status:"
docker-compose -f $COMPOSE_FILE ps
echo ""
echo "🌐 Test API: http://localhost:5001"
echo "🔍 Swagger: http://localhost:5001/swagger"
echo "🗄️  Database: localhost:5434"
echo ""
echo "📋 Useful commands:"
echo "  View logs:    docker-compose -f $COMPOSE_FILE logs -f"
echo "  Stop:         docker-compose -f $COMPOSE_FILE down"
echo "  Restart:      docker-compose -f $COMPOSE_FILE restart"
echo ""
