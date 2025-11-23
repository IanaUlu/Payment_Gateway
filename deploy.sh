#!/bin/bash

# Deploy QiwiGateway to server
# Usage: bash deploy.sh

set -e

echo "?? Deploying QiwiGateway..."

# Stop existing containers
echo "?? Stopping existing containers..."
docker-compose down || true

# Pull latest code (if using git)
if [ -d ".git" ]; then
    echo "?? Pulling latest code from Git..."
    git pull
fi

# Build and start containers
echo "?? Building Docker images..."
docker-compose build --no-cache

echo "?? Starting containers..."
docker-compose up -d

# Wait for database to be ready
echo "? Waiting for database to be ready..."
sleep 10

# Run migrations
echo "???  Running database migrations..."
docker-compose exec -T qiwi_api dotnet ef database update || echo "??  Migrations skipped (might not be configured)"

# Show status
echo ""
echo "? Deployment completed!"
echo ""
echo "?? Container status:"
docker-compose ps
echo ""
echo "?? View logs with: docker-compose logs -f"
echo "?? Check health: curl http://localhost:5000/health"
echo "?? API URL: http://YOUR_SERVER_IP:5000/payment_app.cgi"
