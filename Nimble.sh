#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 节点安装功能
function install_node() {

# 更新系统包列表
apt update

# 检查 Git 等是否已安装
apt install git python3-venv bison screen binutils gcc make bsdmainutils python3-pip -y

# 安装numpy
pip install numpy==1.24.4


# 安装GO
rm -rf /usr/local/go
cd /usr/local
sudo wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
source .bash_profile
go version

# 克隆官方仓库
mkdir $HOME/nimble && cd $HOME/nimble
git clone https://github.com/nimble-technology/wallet-public.git
cd wallet-public
make install

# 创建钱包
nimble-networkd keys add ilovenimble

echo "=============================备份好钱包和助记词，下方需要使用==================================="

sleep 30


# 启动挖矿
read -p "请输入钱包地址: " wallet_addr
export wallet_addr
cd  $HOME/nimble
git clone https://github.com/nimble-technology/nimble-miner-public.git
cd nimble-miner-public
make install
cd  $HOME
screen -dmS nim bash -c 'cd $HOME/nimble; cd nimble-miner-public; source /root/.bashrc; make run addr=$wallet_addr'


}

# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作:"
    echo "1. 安装常规节点"
    read -p "请输入选项（1）: " OPTION

    case $OPTION in
    1) install_node ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
