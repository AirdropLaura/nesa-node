<div align="center">

# 🚀 Nesa Node Setup Guide

[![Nesa](https://img.shields.io/badge/Nesa-Node-blue?style=for-the-badge)](https://nesa.ai)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker)](https://docker.com)
[![Systemd](https://img.shields.io/badge/Systemd-Supported-00BFFF?style=for-the-badge)](https://systemd.io)

**Complete guide for setting up Nesa Validator/Miner Node with professional deployment methods**

[📖 Quick Start](#quick-start) • [🐳 Docker Setup](#docker-setup) • [⚙️ Systemd Setup](#systemd-setup) • [📊 Monitoring](#monitoring)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Docker Setup](#docker-setup)
- [Systemd Setup](#systemd-setup)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Useful Commands](#useful-commands)

---

## 🎯 Overview

Nesa is a decentralized AI inference network. This guide provides **production-ready** setup methods for running a Nesa node:

- **🐳 Docker Method** - Containerized deployment, easy management
- **⚙️ Systemd Method** - Native system service, maximum performance

---

## 💻 System Requirements

### Minimum Requirements
| Component | Specification |
|-----------|---------------|
| **CPU** | 4 cores (x86_64/ARM64) |
| **RAM** | 8 GB |
| **Storage** | 100 GB SSD |
| **Network** | Stable internet, 10 Mbps+ |
| **OS** | Ubuntu 20.04/22.04, Debian 11/12, CentOS 8+ |

### Recommended Requirements
| Component | Specification |
|-----------|---------------|
| **CPU** | 8+ cores |
| **RAM** | 16 GB+ |
| **Storage** | 200 GB NVMe SSD |
| **GPU** | NVIDIA with CUDA (optional) |

---

## 🚀 Quick Start

### One-Liner Bootstrap (Official Method)
```bash
curl -fsSL https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh | bash
```

> ⚠️ **Note**: For production environments, use Docker or Systemd methods below for better control.

---

## 🐳 Docker Setup

### Prerequisites
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add user to docker group (optional, requires logout/login)
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt install docker-compose-plugin
```

### Method 1: Using Docker Compose (Recommended)

1. **Create project directory**
```bash
mkdir -p ~/nesa-node
cd ~/nesa-node
```

2. **Create docker-compose.yml**
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  nesa-node:
    image: nesaorg/nesa-node:latest
    container_name: nesa-node
    restart: unless-stopped
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '2'
          memory: 4G
    
    # Environment variables
    environment:
      - NODE_TYPE=miner
      - NETWORK=mainnet
      - LOG_LEVEL=info
    
    # Volumes for persistence
    volumes:
      - ./data:/root/.nesa
      - ./logs:/var/log/nesa
      - /var/run/docker.sock:/var/run/docker.sock
    
    # Network
    ports:
      - "26656:26656"  # P2P
      - "26657:26657"  # RPC
      - "1317:1317"    # REST API
      - "9090:9090"    # gRPC
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:26657/status"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Optional: Monitoring with Prometheus
  prometheus:
    image: prom/prometheus:latest
    container_name: nesa-prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    ports:
      - "9091:9090"
    profiles:
      - monitoring

volumes:
  prometheus-data:
EOF
```

3. **Create environment file**
```bash
cat > .env << 'EOF'
# Node Configuration
NODE_NAME=my-nesa-node
WALLET_PRIVATE_KEY=your_private_key_here
MONIKER=MyNesaNode

# Network
NETWORK=mainnet
CHAIN_ID=nesa-mainnet-1

# Resources
CPU_LIMIT=4
MEMORY_LIMIT=8G

# Logging
LOG_LEVEL=info
EOF
```

4. **Start the node**
```bash
# Pull latest image
docker compose pull

# Start node
docker compose up -d

# View logs
docker compose logs -f nesa-node
```

### Method 2: Using Docker Run

```bash
# Create directories
mkdir -p ~/.nesa/{data,logs}

# Run container
docker run -d \
  --name nesa-node \
  --restart unless-stopped \
  -p 26656:26656 \
  -p 26657:26657 \
  -p 1317:1317 \
  -p 9090:9090 \
  -v ~/.nesa/data:/root/.nesa \
  -v ~/.nesa/logs:/var/log/nesa \
  -e NODE_TYPE=miner \
  -e NETWORK=mainnet \
  nesaorg/nesa-node:latest
```

### Docker Management Commands

```bash
# View logs
docker compose logs -f nesa-node

# Restart node
docker compose restart nesa-node

# Update to latest version
docker compose pull
docker compose up -d

# Stop node
docker compose down

# Remove all data (Caution!)
docker compose down -v
```

---

## ⚙️ Systemd Setup

### Prerequisites
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl wget git jq build-essential

# Install Go (if needed)
# wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
# sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
# echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
# source ~/.bashrc
```

### Installation Steps

1. **Create system user**
```bash
sudo useradd -r -s /bin/false -m -d /var/lib/nesa nesa
```

2. **Download and install Nesa binary**
```bash
# Create directories
sudo mkdir -p /usr/local/bin/nesa
sudo mkdir -p /var/lib/nesa/{data,logs,config}

# Download latest release (replace with actual URL)
cd /tmp
wget https://github.com/nesaorg/nesa-node/releases/latest/download/nesa-node-linux-amd64

# Install binary
sudo mv nesa-node-linux-amd64 /usr/local/bin/nesa/nesa-node
sudo chmod +x /usr/local/bin/nesa/nesa-node
sudo ln -sf /usr/local/bin/nesa/nesa-node /usr/local/bin/nesa-node

# Set ownership
sudo chown -R nesa:nesa /var/lib/nesa
```

3. **Initialize node configuration**
```bash
sudo -u nesa nesa-node init \
  --moniker "MyNesaNode" \
  --chain-id nesa-mainnet-1 \
  --home /var/lib/nesa/data
```

4. **Create systemd service file**
```bash
sudo tee /etc/systemd/system/nesa-node.service > /dev/null << 'EOF'
[Unit]
Description=Nesa Validator/Miner Node
Documentation=https://nesa.ai/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=nesa
Group=nesa

# Working directory
WorkingDirectory=/var/lib/nesa

# Binary execution
ExecStart=/usr/local/bin/nesa-node start \
  --home /var/lib/nesa/data \
  --log_level info

# Restart policy
Restart=always
RestartSec=10
StartLimitInterval=60s
StartLimitBurst=3

# Resource limits
LimitNOFILE=65535
LimitNPROC=4096

# Environment
Environment="HOME=/var/lib/nesa"
Environment="LOG_LEVEL=info"

# Logging
StandardOutput=append:/var/log/nesa/nesa-node.log
StandardError=append:/var/log/nesa/nesa-node-error.log
SyslogIdentifier=nesa-node

[Install]
WantedBy=multi-user.target
EOF
```

5. **Create log rotation**
```bash
sudo tee /etc/logrotate.d/nesa-node > /dev/null << 'EOF'
/var/log/nesa/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 nesa nesa
    sharedscripts
    postrotate
        systemctl reload nesa-node || true
    endscript
}
EOF
```

6. **Enable and start service**
```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (auto-start on boot)
sudo systemctl enable nesa-node

# Start service
sudo systemctl start nesa-node

# Check status
sudo systemctl status nesa-node
```

### Systemd Management Commands

```bash
# Check status
sudo systemctl status nesa-node

# Start node
sudo systemctl start nesa-node

# Stop node
sudo systemctl stop nesa-node

# Restart node
sudo systemctl restart nesa-node

# View logs
sudo journalctl -u nesa-node -f

# View logs (last 100 lines)
sudo journalctl -u nesa-node -n 100 --no-pager
```

---

## 🔧 Configuration

### Node Configuration File

Location: `~/.nesa/config/config.toml` (Docker) or `/var/lib/nesa/data/config/config.toml` (Systemd)

```toml
# Example configuration
[rpc]
laddr = "tcp://0.0.0.0:26657"
cors_allowed_origins = ["*"]

[p2p]
laddr = "tcp://0.0.0.0:26656"
external_address = "your-public-ip:26656"
max_num_inbound_peers = 40
max_num_outbound_peers = 10

[mempool]
size = 5000
max_txs_bytes = 1073741824
cache_size = 10000
```

### Wallet Setup

1. **Create new wallet**
```bash
nesa-node keys add my-wallet --keyring-backend file
```

2. **Import existing wallet**
```bash
nesa-node keys add my-wallet --recover --keyring-backend file
```

3. **Check balance**
```bash
nesa-node query bank balances $(nesa-node keys show my-wallet -a)
```

---

## 🏆 Validator Setup

### Prerequisites

- Node sudah running dan synced
- Wallet sudah dibuat dan ada balance (minimum stake)
- Public IP static (recommended)

### Step 1: Check Node Status

Pastikan node sudah synced:
```bash
# Check sync status
curl http://localhost:26657/status | jq '.result.sync_info.catching_up'
# Output: false = synced, true = still syncing

# Check latest block
curl http://localhost:26657/status | jq '.result.sync_info.latest_block_height'
```

### Step 2: Get Validator Public Key

```bash
# Get validator pubkey
nesa-node tendermint show-validator

# Simpan output, contoh:
# {"@type":"/cosmos.crypto.ed25519.PubKey","key":"abcdef123456..."}
```

### Step 3: Create Validator

```bash
# Create validator (adjust parameters as needed)
nesa-node tx staking create-validator \
  --amount=1000000unesa \
  --pubkey=$(nesa-node tendermint show-validator) \
  --moniker="my-nesa-validator" \
  --identity="optional-keybase-id" \
  --website="https://your-website.com" \
  --details="My Nesa Validator Node" \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --from=my-wallet \
  --chain-id=nesa-mainnet-1 \
  --gas=auto \
  --gas-adjustment=1.5 \
  --yes
```

**Parameter explanation:**
| Parameter | Description |
|-----------|-------------|
| `--amount` | Initial stake (1000000unesa = 1 NESA) |
| `--pubkey` | Validator public key dari Step 2 |
| `--moniker` | Nama validator (visible di explorer) |
| `--commission-rate` | Fee yang diambil dari delegators (10%) |
| `--commission-max-rate` | Max commission yang bisa di-set (20%) |
| `--commission-max-change-rate` | Max perubahan commission per hari (1%) |
| `--min-self-delegation` | Minimum stake yang harus di-maintain |
| `--from` | Wallet yang digunakan untuk stake |

### Step 4: Verify Validator

```bash
# Check validator list
nesa-node query staking validators --limit 100

# Check your validator info
nesa-node query staking validator $(nesa-node keys show my-wallet --bech val -a)

# Check validator set (active validators)
nesa-node query tendermint-validator-set | grep $(nesa-node tendermint show-address)
```

### Step 5: Manage Validator

**Edit validator info:**
```bash
nesa-node tx staking edit-validator \
  --moniker="new-name" \
  --website="https://new-website.com" \
  --details="Updated description" \
  --from=my-wallet \
  --chain-id=nesa-mainnet-1
```

**Add more stake (self-delegation):**
```bash
nesa-node tx staking delegate \
  $(nesa-node keys show my-wallet --bech val -a) \
  500000unesa \
  --from=my-wallet \
  --chain-id=nesa-mainnet-1
```

**Unjail validator (if jailed):**
```bash
nesa-node tx slashing unjail \
  --from=my-wallet \
  --chain-id=nesa-mainnet-1
```

### Step 6: Claim Rewards

```bash
# Check rewards
nesa-node query distribution rewards $(nesa-node keys show my-wallet -a)

# Withdraw all rewards
nesa-node tx distribution withdraw-all-rewards \
  --from=my-wallet \
  --chain-id=nesa-mainnet-1 \
  --gas=auto

# Withdraw rewards + commission (for validators)
nesa-node tx distribution withdraw-rewards \
  $(nesa-node keys show my-wallet --bech val -a) \
  --commission \
  --from=my-wallet \
  --chain-id=nesa-mainnet-1
```

---

## 📊 Monitoring

### Method 1: Using Prometheus + Grafana (Docker)

1. **Create prometheus.yml**
```bash
cat > prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'nesa-node'
    static_configs:
      - targets: ['nesa-node:26660']
    metrics_path: /metrics
EOF
```

2. **Start with monitoring**
```bash
docker compose --profile monitoring up -d
```

### Method 2: Simple Monitoring Script

```bash
# Create monitoring script
cat > ~/nesa-monitor.sh << 'EOF'
#!/bin/bash

while true; do
    clear
    echo "=== Nesa Node Monitor ==="
    echo "Date: $(date)"
    echo ""
    
    # Check if node is running
    if systemctl is-active --quiet nesa-node; then
        echo "✅ Node Status: RUNNING"
    else
        echo "❌ Node Status: STOPPED"
    fi
    
    # Check sync status
    SYNC_STATUS=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.catching_up')
    if [ "$SYNC_STATUS" == "false" ]; then
        echo "✅ Sync Status: SYNCED"
    else
        echo "⏳ Sync Status: SYNCING"
    fi
    
    # Latest block
    LATEST_BLOCK=$(curl -s http://localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
    echo "📦 Latest Block: $LATEST_BLOCK"
    
    # Peer count
    PEERS=$(curl -s http://localhost:26657/net_info | jq -r '.result.n_peers')
    echo "👥 Connected Peers: $PEERS"
    
    sleep 10
done
EOF

chmod +x ~/nesa-monitor.sh
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Node won't start
```bash
# Check logs
sudo journalctl -u nesa-node -n 50 --no-pager

# Check ports
sudo netstat -tulpn | grep 26656

# Check disk space
df -h
```

#### 2. Sync is slow
```bash
# Check peer connections
curl http://localhost:26657/net_info | jq '.result.peers | length'

# Add persistent peers in config.toml
persistent_peers = "id1@ip1:26656,id2@ip2:26656"
```

#### 3. Out of memory
```bash
# Check memory usage
free -h

# Add swap (if needed)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 4. Docker container keeps restarting
```bash
# Check logs
docker logs nesa-node --tail 100

# Check resource usage
docker stats nesa-node
```

### Reset Node (Caution!)

```bash
# Docker method
docker compose down -v
rm -rf ~/.nesa/data

# Systemd method
sudo systemctl stop nesa-node
sudo rm -rf /var/lib/nesa/data
sudo systemctl start nesa-node
```

---

## 📚 Useful Commands

### General Commands
```bash
# Check node status
curl http://localhost:26657/status | jq

# Check validators
curl http://localhost:26657/validators | jq

# Query account
nesa-node query account $(nesa-node keys show my-wallet -a)

# Send tokens
nesa-node tx bank send my-wallet recipient_address 1000000unesa \
  --chain-id nesa-mainnet-1 \
  --gas auto \
  --gas-adjustment 1.5
```

### Docker Commands
```bash
# Enter container shell
docker exec -it nesa-node /bin/bash

# Check container stats
docker stats nesa-node

# Copy files from container
docker cp nesa-node:/root/.nesa/config ./backup
```

### Systemd Commands
```bash
# Edit service
sudo systemctl edit --full nesa-node

# Reload after changes
sudo systemctl daemon-reload
sudo systemctl restart nesa-node

# Enable auto-start
sudo systemctl enable nesa-node
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This guide is licensed under the MIT License.

## 🔗 Resources

- [Nesa Official Website](https://nesa.ai)
- [Nesa Bootstrap Script](https://github.com/nesaorg/bootstrap)
- [Nesa Documentation](https://docs.nesa.ai)

---

<div align="center">

**Made with ❤️ by the Nesa Community**

If you found this guide helpful, please ⭐ star this repository!

</div>
