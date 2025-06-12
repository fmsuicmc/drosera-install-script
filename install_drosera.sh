#!/bin/bash

set -e

# Update and install prerequisites
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip ca-certificates gnupg lsb-release

# Install Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

# Install Drosera CLI
curl -L https://app.drosera.io/install | bash
source /root/.bashrc
droseraup

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup

# Install Bun
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc

# Request user input
read -p "Please enter your email address: " user_email
read -p "Please enter your GitHub username: " github_username

read -s -p "Please enter your Drosera private key (64 hex chars, no 0x): " drosera_private_key
echo
read -s -p "Please enter your EVM private key (64 hex chars, no 0x): " evm_private_key
echo
read -p "Please enter your VPS public IP address: " vps_ip

# Validate private keys
if [[ ! "$drosera_private_key" =~ ^[a-fA-F0-9]{64}$ ]]; then
  echo "❌ Invalid Drosera private key format. Must be 64 hex characters with no 0x prefix."
  exit 1
fi
if [[ ! "$evm_private_key" =~ ^[a-fA-F0-9]{64}$ ]]; then
  echo "❌ Invalid EVM private key format. Must be 64 hex characters with no 0x prefix."
  exit 1
fi

# Set up Drosera Trap
mkdir -p ~/my-drosera-trap
cd ~/my-drosera-trap
git config --global user.email "$user_email"
git config --global user.name "$github_username"
forge init -t drosera-network/trap-foundry-template
bun install
forge build || true

# Apply trap
DROSERA_PRIVATE_KEY="$drosera_private_key" drosera apply

# Optional: Make it private and whitelist operator address (edit manually if needed)
# echo -e '\nprivate_trap = true\nwhitelist = ["0xYourOperatorAddress"]' >> drosera.toml

# Download Drosera Operator CLI
cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
chmod +x drosera-operator
sudo mv drosera-operator /usr/bin/
drosera-operator --version

# Register operator
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key "$drosera_private_key"

# Clone Drosera Network repo and configure
cd ~
git clone https://github.com/0xmoei/Drosera-Network.git
cd Drosera-Network
cp .env.example .env
sed -i "s/your_evm_private_key/$evm_private_key/" .env
sed -i "s/your_vps_public_ip/$vps_ip/" .env

# Remove obsolete version key if exists
sed -i '/^version:/d' docker-compose.yaml

# Start the Docker container
docker compose up -d

# View logs
docker compose logs -f

echo "✅ Drosera Operator setup complete!"
echo "🔗 Visit your dashboard: https://app.drosera.io/"
