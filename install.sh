#!/bin/bash
#
# Nesa Node Installation Script
# Supports: Docker and Systemd methods
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. It's recommended to run as a regular user with sudo privileges."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            OS="ubuntu"
        elif command -v yum &> /dev/null; then
            OS="centos"
        fi
    else
        log_error "Unsupported OS. This script supports Linux only."
        exit 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
        log_error "Unsupported architecture: $ARCH"
        exit 1
    fi
    
    # Check RAM (minimum 4GB)
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $TOTAL_RAM -lt 4 ]]; then
        log_warning "Low RAM detected: ${TOTAL_RAM}GB. Recommended: 8GB+"
    fi
    
    log_success "System requirements check passed!"
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        log_success "Docker already installed"
        docker --version
        return
    fi
    
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    
    log_success "Docker installed successfully!"
    log_warning "Please logout and login again for group changes to take effect."
}

# Docker setup
setup_docker() {
    log_info "Setting up Nesa Node with Docker..."
    
    # Create directories
    mkdir -p ~/nesa-node/{data,logs,config}
    cd ~/nesa-node
    
    # Create docker-compose.yml
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nesa-node:
    image: nesaorg/nesa-node:latest
    container_name: nesa-node
    restart: unless-stopped
    
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
    
    environment:
      - NODE_TYPE=miner
      - NETWORK=mainnet
      - LOG_LEVEL=info
    
    volumes:
      - ./data:/root/.nesa
      - ./logs:/var/log/nesa
    
    ports:
      - "26656:26656"
      - "26657:26657"
      - "1317:1317"
      - "9090:9090"
    
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:26657/status"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

    # Create .env file
    cat > .env << 'EOF'
# Node Configuration
NODE_NAME=nesa-node
NETWORK=mainnet
LOG_LEVEL=info

# Resource limits
CPU_LIMIT=4
MEMORY_LIMIT=8G
EOF

    # Start node
    docker compose pull
    docker compose up -d
    
    log_success "Nesa Node (Docker) started successfully!"
    log_info "Check logs with: docker compose logs -f nesa-node"
}

# Systemd setup
setup_systemd() {
    log_info "Setting up Nesa Node with Systemd..."
    
    # Create user
    if ! id -u nesa &>/dev/null; then
        sudo useradd -r -s /bin/false -m -d /var/lib/nesa nesa
    fi
    
    # Create directories
    sudo mkdir -p /var/lib/nesa/{data,logs,config}
    sudo mkdir -p /usr/local/bin/nesa
    
    # Download binary (placeholder - update with actual URL)
    log_info "Downloading Nesa binary..."
    # wget -O /tmp/nesa-node.tar.gz "https://github.com/nesaorg/nesa-node/releases/latest/download/nesa-node-linux-amd64.tar.gz"
    # sudo tar -xzf /tmp/nesa-node.tar.gz -C /usr/local/bin/nesa/
    
    # Create systemd service
    sudo tee /etc/systemd/system/nesa-node.service > /dev/null << 'EOF'
[Unit]
Description=Nesa Validator/Miner Node
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=nesa
Group=nesa
WorkingDirectory=/var/lib/nesa
ExecStart=/usr/local/bin/nesa/nesa-node start --home /var/lib/nesa/data
Restart=always
RestartSec=10
LimitNOFILE=65535
StandardOutput=append:/var/log/nesa/nesa-node.log
StandardError=append:/var/log/nesa/nesa-node-error.log

[Install]
WantedBy=multi-user.target
EOF

    # Set permissions
    sudo chown -R nesa:nesa /var/lib/nesa
    sudo chmod +x /usr/local/bin/nesa/nesa-node 2>/dev/null || true
    
    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable nesa-node
    
    log_success "Nesa Node (Systemd) configured successfully!"
    log_info "Start with: sudo systemctl start nesa-node"
}

# Main menu
show_menu() {
    echo ""
    echo "========================================"
    echo "    🚀 Nesa Node Setup Wizard"
    echo "========================================"
    echo ""
    echo "1) Docker Setup (Recommended)"
    echo "2) Systemd Setup (Advanced)"
    echo "3) Check Node Status"
    echo "4) View Logs"
    echo "5) Uninstall"
    echo "6) Exit"
    echo ""
}

# Main function
main() {
    check_root
    check_requirements
    
    while true; do
        show_menu
        read -p "Select option [1-6]: " choice
        
        case $choice in
            1)
                install_docker
                setup_docker
                ;;
            2)
                setup_systemd
                ;;
            3)
                if systemctl is-active --quiet nesa-node 2>/dev/null; then
                    log_success "Systemd node is running"
                    sudo systemctl status nesa-node --no-pager
                elif docker ps | grep -q nesa-node; then
                    log_success "Docker node is running"
                    docker ps | grep nesa-node
                else
                    log_warning "No running node found"
                fi
                ;;
            4)
                if systemctl is-active --quiet nesa-node 2>/dev/null; then
                    sudo journalctl -u nesa-node -f
                elif docker ps | grep -q nesa-node; then
                    docker logs -f nesa-node
                else
                    log_warning "No running node found"
                fi
                ;;
            5)
                log_warning "This will remove all node data!"
                read -p "Are you sure? (yes/no): " confirm
                if [[ $confirm == "yes" ]]; then
                    docker compose down -v 2>/dev/null || true
                    sudo systemctl stop nesa-node 2>/dev/null || true
                    sudo systemctl disable nesa-node 2>/dev/null || true
                    log_success "Node uninstalled"
                fi
                ;;
            6)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid option"
                ;;
        esac
    done
}

# Run main function
main
