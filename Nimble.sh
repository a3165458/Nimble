#!/bin/bash

# 检查是否以root用户运行脚本
# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。/This script needs to be run with root user privileges."
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。/Please try to switch to root user with 'sudo -i' command, then run this script again."
    exit 1
fi

# 导入Socks5代理
# Import Socks5 proxy
read -p "请输入Socks5代理地址 (格式为 host:port)，如不需要代理请留空: /Please enter the Socks5 proxy address (format host:port), leave blank if no proxy is needed: " proxy

if [ ! -z "$proxy" ]; then
    export http_proxy=socks5://$proxy
    export https_proxy=socks5://$proxy
    echo "已设置Socks5代理为: $proxy /Socks5 proxy is set to: $proxy"
else
    echo "未设置代理 /No proxy set"
fi

# 节点安装功能
# Node installation function
function install_node() {

# 更新系统包列表
# Update system package list
apt update

# 检查 Git 等是否已安装
# Check if Git and others are already installed
apt install git python3-venv bison screen binutils gcc make bsdmainutils python3-pip -y

# 安装numpy
# Install numpy
pip install numpy==1.24.4


# 安装GO
# Install GO
rm -rf /usr/local/go
cd /usr/local
wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
go version

# 克隆官方仓库
# Clone the official repository
mkdir $HOME/nimble && cd $HOME/nimble
git clone https://github.com/nimble-technology/wallet-public.git
cd wallet-public
make install

# 创建钱包
# Create a wallet
nimble-networkd keys add ilovenimble

echo "=============================备份好钱包和助记词，下方需要使用==================================="
echo "=============================Make sure to backup your wallet and mnemonic phrase, it will be needed below==================================="

read -p "是否已经备份好助记词? Have you backed up the mnemonic phrase? (y/n) " backup_confirmed

# 如果用户没有确认备份,则退出脚本
# If the user did not confirm the backup, then exit the script
if [ "$backup_confirmed" != "y" ]; then
        echo "请先备份好助记词,然后再继续执行脚本。/Please backup the mnemonic phrase first, then continue running the script."
        exit 1
    fi


# 启动挖矿
# Start mining
read -p "请输入钱包地址: Please enter your wallet address: " wallet_addr
export wallet_addr
cd  $HOME/nimble
git clone https://github.com/nimble-technology/nimble-miner-public.git
cd nimble-miner-public
make install
cd  $HOME
cd $HOME/nimble/nimble-miner-public
source ./nimenv_localminers/bin/activate
screen -dmS nim bash -c 'make run addr=$wallet_addr'


}

# 主菜单
# Main menu
function main_menu() {
    clear
    echo "请选择要执行的操作: /Please select an operation to execute:"
    echo "1. 安装常规节点 /Install a regular node"
    read -p "请输入选项（1）: Please enter your choice (1): " OPTION

    case $OPTION in
    1) install_node ;;
    *) echo "无效选项。/Invalid option." ;;
    esac
}

# 显示主菜单
# Show the main menu
main_menu
