#!/bin/bash

# Update and install prerequisites
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ca-certificates gnupg lsb-release

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

# Request information from the user
echo "Please enter your email address:"
read user_email

echo "Please enter your GitHub username:"
read github_username

echo "Please enter your Drosera private key:"
read drosera_private_key

echo "Please enter your EVM private key:"
read evm_private_key

echo "Please enter your VPS public IP address:"
read vps_ip

# Set up Drosera Trap project
mkdir my-drosera-trap
cd my-drosera-trap
git config --global user.email "$user_email"
git config --global user.name "$github_username"
forge init -t drosera-network/trap-foundry-template
curl -fsSL https://bun.sh/install | bash
bun install
forge build

# Apply Trap
DROSERA_PRIVATE_KEY="$drosera_private_key" drosera apply

# Set up Drosera Operator
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
./drosera-operator --version
sudo cp drosera-operator /usr/bin
drosera-operator

# Register with Drosera Operator
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key "$drosera_private_key"

# Set up Drosera Network
git clone https://github.com/0xmoei/Drosera-Network
cd Drosera-Network
cp .env.example .env

# Edit the .env file with the values entered by the user
sed -i "s/your_evm_private_key/$evm_private_key/" .env
sed -i "s/your_vps_public_ip/$vps_ip/" .env

docker compose up -d

# View logs
cd Drosera-Network
docker compose logs -f
