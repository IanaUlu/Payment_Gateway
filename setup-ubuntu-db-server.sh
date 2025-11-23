#!/bin/bash
# Ubuntu Server Setup - Database Server (Server 2)
# This script installs and configures PostgreSQL on a dedicated database server
# Run as root or with sudo

set -e

echo "=========================================="
echo "  🗄️  QIWI Gateway - Database Server Setup"
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

# Ask for configuration
read -p "Enter API Server Private IP (to whitelist, e.g., 10.0.0.1): " API_SERVER_IP
read -p "Enter Database Name (default: qiwi_gateway_prod): " DB_NAME
DB_NAME=${DB_NAME:-qiwi_gateway_prod}
read -p "Enter Database User (default: qiwi_prod_user): " DB_USER
DB_USER=${DB_USER:-qiwi_prod_user}
read -sp "Enter Database Password (STRONG password!): " DB_PASSWORD
echo ""
read -p "Enter Backup Retention Days (default: 30): " BACKUP_DAYS
BACKUP_DAYS=${BACKUP_DAYS:-30}

echo ""
echo -e "${YELLOW}📦 Step 1: System Update${NC}"
apt-get update
apt-get upgrade -y
echo -e "${GREEN}✓ System updated${NC}"

echo ""
echo -e "${YELLOW}📦 Step 2: Installing Required Packages${NC}"
apt-get install -y \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    vim \
    htop \
    postgresql-common

echo -e "${GREEN}✓ Required packages installed${NC}"

echo ""
echo -e "${YELLOW}🗄️  Step 3: Installing PostgreSQL 15${NC}"

# Add PostgreSQL repository
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Update and install PostgreSQL
apt-get update
apt-get install -y postgresql-15 postgresql-contrib-15

echo -e "${GREEN}✓ PostgreSQL 15 installed${NC}"
sudo -u postgres psql --version

echo ""
echo -e "${YELLOW}🔧 Step 4: Configuring PostgreSQL${NC}"

# Start and enable PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql << PSQLEOF
-- Create user
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';

-- Create database
CREATE DATABASE $DB_NAME OWNER $DB_USER;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Allow user to create tables
\c $DB_NAME
GRANT ALL ON SCHEMA public TO $DB_USER;
GRANT CREATE ON SCHEMA public TO $DB_USER;

\q
PSQLEOF

echo -e "${GREEN}✓ Database and user created${NC}"

echo ""
echo -e "${YELLOW}🔐 Step 5: Configuring PostgreSQL Security${NC}"

# Get PostgreSQL version and config directory
PG_VERSION="15"
PG_CONF_DIR="/etc/postgresql/$PG_VERSION/main"

# Backup original configs
cp $PG_CONF_DIR/postgresql.conf $PG_CONF_DIR/postgresql.conf.backup
cp $PG_CONF_DIR/pg_hba.conf $PG_CONF_DIR/pg_hba.conf.backup

# Configure postgresql.conf for remote connections
cat >> $PG_CONF_DIR/postgresql.conf << EOF

# Custom Configuration for Production
listen_addresses = '*'
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 1MB
min_wal_size = 1GB
max_wal_size = 4GB

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_timezone = 'Europe/Istanbul'

# SSL
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
EOF

# Configure pg_hba.conf to allow API server
cat > $PG_CONF_DIR/pg_hba.conf << EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Allow local connections
local   all             postgres                                peer
local   all             all                                     peer

# Allow API server to connect with SSL
hostssl $DB_NAME        $DB_USER        $API_SERVER_IP/32       scram-sha-256

# Allow localhost connections
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

# Reject all other connections
host    all             all             0.0.0.0/0               reject
EOF

# Restart PostgreSQL
systemctl restart postgresql

echo -e "${GREEN}✓ PostgreSQL security configured${NC}"

echo ""
echo -e "${YELLOW}🔥 Step 6: Configuring Firewall${NC}"

# Reset firewall
ufw --force reset

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp comment 'SSH'

# Allow PostgreSQL from API server only
ufw allow from $API_SERVER_IP to any port 5432 proto tcp comment 'PostgreSQL from API server'

# Enable firewall
ufw --force enable

echo -e "${GREEN}✓ Firewall configured${NC}"
ufw status

echo ""
echo -e "${YELLOW}📁 Step 7: Setting up Backup Directory${NC}"

# Create backup directory
BACKUP_DIR="/var/backups/postgresql"
mkdir -p $BACKUP_DIR
chown postgres:postgres $BACKUP_DIR
chmod 700 $BACKUP_DIR

echo -e "${GREEN}✓ Backup directory created: $BACKUP_DIR${NC}"

echo ""
echo -e "${YELLOW}⏰ Step 8: Configuring Automated Backups${NC}"

# Create backup script
cat > /usr/local/bin/pg-backup.sh << 'BACKUPEOF'
#!/bin/bash
# PostgreSQL Automated Backup Script

BACKUP_DIR="/var/backups/postgresql"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
RETENTION_DAYS="$BACKUP_DAYS"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

# Create backup
sudo -u postgres pg_dump $DB_NAME | gzip > $BACKUP_FILE

# Check if backup was successful
if [ $? -eq 0 ]; then
    echo "$(date): Backup successful: $BACKUP_FILE" >> /var/log/pg-backup.log
    
    # Delete old backups
    find $BACKUP_DIR -name "${DB_NAME}_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    echo "$(date): Old backups cleaned (retention: $RETENTION_DAYS days)" >> /var/log/pg-backup.log
else
    echo "$(date): Backup FAILED" >> /var/log/pg-backup.log
    exit 1
fi
BACKUPEOF

# Replace variables in backup script
sed -i "s/\$DB_NAME/$DB_NAME/g" /usr/local/bin/pg-backup.sh
sed -i "s/\$DB_USER/$DB_USER/g" /usr/local/bin/pg-backup.sh
sed -i "s/\$BACKUP_DAYS/$BACKUP_DAYS/g" /usr/local/bin/pg-backup.sh

# Make script executable
chmod +x /usr/local/bin/pg-backup.sh

# Create log file
touch /var/log/pg-backup.log
chmod 644 /var/log/pg-backup.log

# Add to crontab (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/pg-backup.sh") | crontab -

echo -e "${GREEN}✓ Automated backup configured (daily at 2 AM)${NC}"

echo ""
echo -e "${YELLOW}📊 Step 9: Testing Database Connection${NC}"

# Test connection
if sudo -u postgres psql -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
    sudo -u postgres psql -d $DB_NAME -c "SELECT version();"
else
    echo -e "${RED}❌ Database connection failed${NC}"
fi

echo ""
echo -e "${YELLOW}🔍 Step 10: Database Statistics${NC}"

sudo -u postgres psql -d $DB_NAME << 'STATSEOF'
-- Database size
SELECT pg_size_pretty(pg_database_size(current_database())) as database_size;

-- Show settings
SELECT name, setting FROM pg_settings WHERE name IN ('max_connections', 'shared_buffers', 'effective_cache_size');
STATSEOF

echo ""
echo -e "${GREEN}=========================================="
echo "  ✅ DATABASE SERVER SETUP COMPLETE!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📊 Database Information:${NC}"
echo "  Database Name: $DB_NAME"
echo "  Database User: $DB_USER"
echo "  PostgreSQL Version: 15"
echo "  Listening Port: 5432"
echo "  Backup Directory: $BACKUP_DIR"
echo "  Backup Schedule: Daily at 2 AM (retention: $BACKUP_DAYS days)"
echo ""
echo -e "${BLUE}🔐 Security:${NC}"
echo "  ✓ Firewall configured (only API server allowed)"
echo "  ✓ SSL enabled for connections"
echo "  ✓ Password authentication (scram-sha-256)"
echo "  ✓ All other connections rejected"
echo ""
echo -e "${BLUE}📋 Connection String for API Server:${NC}"
echo "  Host=$(hostname -I | awk '{print $1}');Port=5432;Database=$DB_NAME;Username=$DB_USER;Password=$DB_PASSWORD;SSL Mode=Require;Trust Server Certificate=true"
echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo "  Connect to DB:        sudo -u postgres psql -d $DB_NAME"
echo "  View connections:     sudo -u postgres psql -c \"SELECT * FROM pg_stat_activity;\""
echo "  Check logs:           tail -f /var/log/postgresql/postgresql-*.log"
echo "  Manual backup:        /usr/local/bin/pg-backup.sh"
echo "  List backups:         ls -lh $BACKUP_DIR"
echo "  Service status:       systemctl status postgresql"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "  1. Test connection from API server"
echo "  2. Update API server's .env.production with this connection string"
echo "  3. Setup monitoring (pg_stat_statements, monitoring tools)"
echo "  4. Consider setting up replication for high availability"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Save these credentials securely!${NC}"
echo ""
