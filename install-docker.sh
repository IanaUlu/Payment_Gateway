#!/bin/bash

# Install Docker on Ubuntu 14.04
# Run with: sudo bash install-docker.sh

set -e

echo "?? Installing Docker on Ubuntu 14.04..."

# Update package index
apt-get update

# Install prerequisites
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add Docker repository
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update package index again
apt-get update

# Install Docker
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start Docker service
service docker start

# Enable Docker to start on boot
update-rc.d docker defaults

# Add current user to docker group (optional, logout required to take effect)
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    echo "? User $SUDO_USER added to docker group. Please logout and login again."
fi

# Verify installation
echo ""
echo "?? Docker installation completed!"
echo ""
docker --version
docker-compose --version
echo ""
echo "??  If you added your user to docker group, please logout and login again."
