#!/bin/bash
# Ubuntu Server Setup - API Server (Server 1)
# This script installs and configures everything needed for the API server
# Run as root or with sudo

set -e

echo "=========================================="
echo "  🚀 QIWI Gateway - API Server Setup"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 System Information:${NC}"
echo "OS: $(lsb_release -ds)"
echo "Kernel: $(uname -r)"
echo "Hostname: $(hostname)"
echo "Private IP: $(hostname -I | awk '{print $1}')"
echo ""

# Ask for configuration BEFORE any installation
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  API SERVER CONFIGURATION${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

read -p "Enter Database Server Private IP: " DB_SERVER_IP
while [ -z "$DB_SERVER_IP" ]; do
    echo -e "${RED}Database Server IP cannot be empty!${NC}"
    read -p "Enter Database Server IP: " DB_SERVER_IP
done

read -p "Enter Database Name (e.g., payment_gateway_test): " DB_NAME
while [ -z "$DB_NAME" ]; do
    echo -e "${RED}Database name cannot be empty!${NC}"
    read -p "Enter Database Name: " DB_NAME
done
DB_NAME_LOWER=$(echo "$DB_NAME" | tr '[:upper:]' '[:lower:]')

read -p "Enter Database User (e.g., pgtest): " DB_USER
while [ -z "$DB_USER" ]; do
    echo -e "${RED}Database user cannot be empty!${NC}"
    read -p "Enter Database User: " DB_USER
done

while true; do
    read -sp "Enter Database Password: " DB_PASSWORD
    echo ""
    if [ ${#DB_PASSWORD} -lt 12 ]; then
        echo -e "${RED}Password must be at least 12 characters!${NC}"
    else
        read -sp "Confirm Database Password: " DB_PASSWORD_CONFIRM
        echo ""
        if [ "$DB_PASSWORD" = "$DB_PASSWORD_CONFIRM" ]; then
            break
        else
            echo -e "${RED}Passwords do not match!${NC}"
        fi
    fi
done

read -p "Enter Domain Name (optional, press Enter to skip): " DOMAIN_NAME
read -p "Enter Email for SSL (optional, press Enter to skip): " SSL_EMAIL

echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo "  Database Server IP: $DB_SERVER_IP"
echo "  Database Name: $DB_NAME_LOWER"
echo "  Database User: $DB_USER"
echo "  Domain: ${DOMAIN_NAME:-Not configured}"
echo "  SSL Email: ${SSL_EMAIL:-Not configured}"
echo ""
read -p "Continue with installation? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📦 Step 1: System Update${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
echo -e "${GREEN}✓ System updated${NC}"

echo ""
echo -e "${YELLOW}📦 Step 2: Installing Required Packages${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ufw \
    git \
    htop \
    vim

echo -e "${GREEN}✓ Required packages installed${NC}"

echo ""
echo -e "${YELLOW}🐳 Step 3: Installing Docker${NC}"

# Remove old versions if exist
apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add current user to docker group
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
fi

echo -e "${GREEN}✓ Docker installed successfully${NC}"
docker --version
docker compose version

echo ""
echo -e "${YELLOW}🔥 Step 4: Configuring Firewall (UFW)${NC}"

# Reset firewall
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (important!)
ufw allow 22/tcp comment 'SSH'

# Allow HTTP/HTTPS
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Allow API port (if accessed directly)
ufw allow 5000/tcp comment 'API Direct Access'

# Enable firewall
ufw --force enable

echo -e "${GREEN}✓ Firewall configured${NC}"
ufw status

echo ""
echo -e "${YELLOW}📁 Step 5: Setting up Application Directory${NC}"

# Create application directory
APP_DIR="/opt/qiwi-gateway"
mkdir -p $APP_DIR
cd $APP_DIR

# Create necessary directories
mkdir -p logs backups data nginx/ssl nginx/conf.d

echo -e "${GREEN}✓ Application directory created: $APP_DIR${NC}"

echo ""
echo -e "${YELLOW}📝 Step 6: Creating Configuration Files${NC}"

# Create .env.production file
cat > .env.production << EOF
# Production Environment Variables
# Database Configuration (Remote Server)
POSTGRES_HOST=$DB_SERVER_IP
POSTGRES_PORT=5432
POSTGRES_DB=$DB_NAME_LOWER
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASSWORD

# Application Settings
ASPNETCORE_ENVIRONMENT=Production
TZ=Europe/Istanbul
API_PORT=5000

# Security
JWT_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -base64 32)

# Domain (if applicable)
DOMAIN=$DOMAIN_NAME
SSL_EMAIL=$SSL_EMAIL
EOF

chmod 600 .env.production

echo -e "${GREEN}✓ Environment file created${NC}"

# Create docker-compose.production-remote-db.yml
cat > docker-compose.yml << 'EOF'
# Docker Compose - Production (Remote Database)
# API Server only - connects to separate database server

services:
  api:
    image: qiwigateway:production
    container_name: qiwi_api_prod
    restart: always
    build:
      context: ./app
      dockerfile: Dockerfile
      args:
        BUILDCONFIG: Release
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      ASPNETCORE_URLS: http://+:5000
      ConnectionStrings__DefaultConnection: "Host=${POSTGRES_HOST};Port=${POSTGRES_PORT};Database=${POSTGRES_DB};Username=${POSTGRES_USER};Password=${POSTGRES_PASSWORD};SSL Mode=Require;Trust Server Certificate=true"
      TZ: ${TZ}
    volumes:
      - ./logs:/app/Logs
      - ./data:/app/Data
    networks:
      - qiwi_network
    ports:
      - "127.0.0.1:5000:5000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  nginx:
    image: nginx:alpine
    container_name: qiwi_nginx
    restart: always
    depends_on:
      - api
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/html:/usr/share/nginx/html:ro
    networks:
      - qiwi_network
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"

networks:
  qiwi_network:
    driver: bridge
EOF

echo -e "${GREEN}✓ Docker Compose configuration created${NC}"

echo ""
echo -e "${YELLOW}🌐 Step 7: Configuring Nginx${NC}"

# Create nginx.conf
cat > nginx/nginx.conf << 'NGINXEOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 20M;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss;

    # Include all configs
    include /etc/nginx/conf.d/*.conf;
}
NGINXEOF

# Create default site config
cat > nginx/conf.d/default.conf << 'NGINXCONF'
# HTTP Server
server {
    listen 80 default_server;
    server_name _;

    location /health {
        proxy_pass http://api:5000/health;
        access_log off;
    }

    location / {
        proxy_pass http://api:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINXCONF

echo -e "${GREEN}✓ Nginx configured${NC}"

echo ""
echo -e "${YELLOW}📥 Step 8: Cloning Application Code${NC}"

# Clone repository
if [ ! -d "app/.git" ]; then
    read -p "Enter GitHub repository URL: " REPO_URL
    git clone $REPO_URL app
    cd app
    git checkout main
    cd ..
else
    echo "Repository already exists, pulling latest changes..."
    cd app
    git pull origin main
    cd ..
fi

echo -e "${GREEN}✓ Application code ready${NC}"

echo ""
echo -e "${YELLOW}🏗️  Step 9: Building and Starting Services${NC}"

# Load environment variables
set -a
source .env.production
set +a

# Build and start containers
docker compose build --no-cache
docker compose up -d

echo -e "${GREEN}✓ Services started${NC}"

echo ""
echo -e "${YELLOW}⏳ Step 10: Waiting for services to be healthy...${NC}"
sleep 15

# Check health
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ API is healthy!${NC}"
else
    echo -e "${RED}⚠️  API health check failed. Check logs:${NC}"
    echo "docker compose logs api"
fi

echo ""
echo -e "${YELLOW}🔐 Step 11: SSL Configuration (Optional)${NC}"

if [ -n "$DOMAIN_NAME" ] && [ -n "$SSL_EMAIL" ]; then
    echo "Installing Certbot for Let's Encrypt SSL..."
    apt-get install -y certbot python3-certbot-nginx
    
    echo "Obtaining SSL certificate..."
    certbot --nginx -d $DOMAIN_NAME --email $SSL_EMAIL --agree-tos --non-interactive --redirect
    
    # Setup auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    echo -e "${GREEN}✓ SSL certificate installed and auto-renewal configured${NC}"
else
    echo -e "${YELLOW}Skipping SSL setup. You can run certbot manually later.${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  ✅ API SERVER SETUP COMPLETE!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📊 Server Information:${NC}"
echo "  Application Directory: $APP_DIR"
echo "  Database Server: $DB_SERVER_IP"
echo "  API Port: 5000"
if [ -n "$DOMAIN_NAME" ]; then
    echo "  Domain: https://$DOMAIN_NAME"
else
    echo "  Local Access: http://$(hostname -I | awk '{print $1}')"
fi
echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo "  Check status:     cd $APP_DIR && docker compose ps"
echo "  View logs:        cd $APP_DIR && docker compose logs -f"
echo "  Restart:          cd $APP_DIR && docker compose restart"
echo "  Stop:             cd $APP_DIR && docker compose down"
echo "  Update app:       cd $APP_DIR/app && git pull && cd .. && docker compose up -d --build"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "  1. Test API: curl http://localhost:5000/health"
echo "  2. Configure SSL if not done: certbot --nginx"
echo "  3. Setup monitoring and backups"
echo "  4. Configure domain DNS to point to this server"
echo ""
