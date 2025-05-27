#!/bin/bash

# به‌روزرسانی و نصب پیش‌نیازها
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev ca-certificates gnupg lsb-release

# نصب Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

# نصب Drosera CLI
curl -L https://app.drosera.io/install | bash
source /root/.bashrc
droseraup

# نصب Foundry
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup

# نصب Bun
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc

# درخواست اطلاعات از کاربر
echo "لطفاً آدرس ایمیل خود را وارد کنید:"
read user_email

echo "لطفاً نام کاربری گیت‌هاب خود را وارد کنید:"
read github_username

echo "لطفاً کلید خصوصی Drosera خود را وارد کنید:"
read drosera_private_key

echo "لطفاً کلید خصوصی EVM خود را وارد کنید:"
read evm_private_key

echo "لطفاً آدرس IP عمومی VPS خود را وارد کنید:"
read vps_ip

# راه‌اندازی پروژه Drosera Trap
mkdir my-drosera-trap
cd my-drosera-trap
git config --global user.email "$user_email"
git config --global user.name "$github_username"
forge init -t drosera-network/trap-foundry-template
curl -fsSL https://bun.sh/install | bash
bun install
forge build

# اعمال Trap
DROSERA_PRIVATE_KEY="$drosera_private_key" drosera apply

# راه‌اندازی Drosera Operator
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
./drosera-operator --version
sudo cp drosera-operator /usr/bin
drosera-operator

# ثبت‌نام در Drosera Operator
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key "$drosera_private_key"

# راه‌اندازی Drosera Network
git clone https://github.com/0xmoei/Drosera-Network
cd Drosera-Network
cp .env.example .env

# ویرایش فایل .env با مقادیر وارد شده توسط کاربر
sed -i "s/your_evm_private_key/$evm_private_key/" .env
sed -i "s/your_vps_public_ip/$vps_ip/" .env

docker compose up -d

# مشاهده لاگ‌ها
cd Drosera-Network
docker compose logs -f
