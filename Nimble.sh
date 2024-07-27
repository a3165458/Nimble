#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。/This script needs to be run with root user privileges."
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。/Please try to switch to root user with 'sudo -i' command, then run this script again."
    exit 1
fi

# 导入Socks5代理
read -p "请输入HTTP代理地址 (格式为 host:port)，如不需要代理请留空: /Please enter the HTTP proxy address (format host:port), leave blank if no proxy is needed: " proxy
if [ ! -z "$proxy" ]; then
    export http_proxy=http://$proxy
    export https_proxy=http://$proxy
    echo "已设置HTTP代理为: $proxy /HTTP proxy is set to: $proxy"
else
    echo "未设置代理 /No proxy set"
fi

# 节点安装功能
function install_node() {
    apt update
    apt install -y git nano python3-venv bison screen binutils gcc make bsdmainutils python3-pip build-essential



    # 安装GO
    rm -rf /usr/local/go
    wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -P /tmp/
    tar -C /usr/local -xzf /tmp/go1.22.1.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    go version

    # 克隆官方仓库并安装
    mkdir -p $HOME/nimble && cd $HOME/nimble
    git clone https://github.com/nimble-technology/wallet-public.git
    cd wallet-public
    make install

    # 创建钱包
    echo "首次创建需要生成两个钱包，一个作为主钱包，一个作为挖矿钱包，需要提交官方审核。"
    read -p "请输入你想要创建的钱包数量/Enter the number of wallets you want to create: " wallet_count
    for i in $(seq 1 $wallet_count); do
        wallet_name="wallet$i"
        nimble-networkd keys add $wallet_name --keyring-backend test
        echo "钱包 $wallet_name 已创建/Wallet $wallet_name has been created."
    done

    echo "=============================备份好钱包和助记词，下方需要使用==================================="
    echo "=============================Make sure to backup your wallet and mnemonic phrase, it will be needed below==================================="

    # 确认备份
    read -p "是否已经备份好助记词? Have you backed up the mnemonic phrase? (y/n) " backup_confirmed
    if [ "$backup_confirmed" != "y" ]; then
            echo "请先备份好助记词,然后再继续执行脚本。/Please backup the mnemonic phrase first, then continue running the script."
            exit 1
    fi

    cd $HOME 
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm -rf ~/miniconda3/miniconda.sh
    ~/miniconda3/bin/conda init bash
    source $HOME/.bashrc

    conda create -n nimble python=3.11 -y
    conda activate nimble
    
    # 启动挖矿
    read -p "请输入挖矿钱包地址: Please enter your mining wallet address: " wallet_addr
    read -p "请输入主钱包地址: Please enter your mining wallet address: " master_wallet_address
    export wallet_addr
    cd $HOME/nimble
    git clone https://github.com/nimble-technology/nimble-miner-public.git
    cd nimble-miner-public
    make install
    source ./nimenv_localminers/bin/activate
    screen -dmS nim bash -c "make run addr=$wallet_addr master_wallet=$master_wallet_address"

    echo "安装完成，请输入命令 'screen -r nim' 查看运行状态。/Installation complete, enter 'screen -r nim' to view the running status."
}

function lonely_start() {
    read -p "请输入挖矿钱包地址: Please enter your mining wallet address: " wallet_addr
    read -p "请输入主钱包地址: Please enter your mining wallet address: " master_wallet_address
    export wallet_addr
    cd $HOME/nimble/nimble-miner-public
    source ./nimenv_localminers/bin/activate
    screen -dmS nim bash -c "make run addr=$wallet_addr master_wallet=$master_wallet_address"

    echo "独立启动，请输入命令 'screen -r nim' 查看运行状态。/Installation complete, enter 'screen -r nim' to view the running status."
}

function uninstall_node() {

    screen -S nim -X quit
    rm -rf $HOME/nimble
    
}
    
function install_farm() {
    apt update
    apt install -y git nano python3-venv bison screen binutils gcc make bsdmainutils python3-pip build-essential
    
    cd $HOME 
    mkdir -p ~/miniconda3
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
    rm -rf ~/miniconda3/miniconda.sh
    ~/miniconda3/bin/conda init bash
    source $HOME/.bashrc

    conda create -n nimble python=3.11 -y
    conda activate nimble
    
    # 启动挖矿
    read -p "请输入挖矿钱包地址: Please enter your mining wallet address: " wallet_addr
    read -p "请输入主钱包地址: Please enter your mining wallet address: " master_wallet_address
    export wallet_addr
    cd $HOME/nimble
    git clone https://github.com/nimble-technology/nimble-miner-public.git
    cd nimble-miner-public
    make install
    source ./nimenv_localminers/bin/activate
    screen -dmS nim bash -c "make run addr=$wallet_addr master_wallet=$master_wallet_address"

    echo "安装完成，请输入命令 'screen -r nim' 查看运行状态。/Installation complete, enter 'screen -r nim' to view the running status."

    }


function multiple_farm() {
    # 获取用户输入
    read -p "请输入挖矿钱包地址: Please enter your mining wallet address: " wallet_addr
    read -p "请输入主钱包地址: Please enter your main wallet address: " master_wallet_address
    export wallet_addr

    # 检查并安装挖矿软件
    if [ ! -d "$HOME/nimble/nimble-miner-public" ]; then
        cd "$HOME/nimble" || mkdir -p "$HOME/nimble" && cd "$HOME/nimble"
        git clone https://github.com/nimble-technology/nimble-miner-public.git
        cd nimble-miner-public
        make install
    else
        cd "$HOME/nimble/nimble-miner-public"
    fi

    # 获取可用GPU列表
    available_gpus=$(nvidia-smi --query-gpu=index --format=csv,noheader | tr '\n' ',' | sed 's/,$//')
    echo "可用的GPU: $available_gpus"

    # 获取用户选择的GPU
    while true; do
        read -p "请输入要启动挖矿的GPU编号(以逗号分隔): Please enter the GPU numbers to start mining (separated by commas): " gpu_list
        if [[ $gpu_list =~ ^[0-9]+(,[0-9]+)*$ ]]; then
            IFS=',' read -ra gpu_array <<< "$gpu_list"
            valid_input=true
            for gpu in "${gpu_array[@]}"; do
                if [[ ! $available_gpus =~ (^|,)$gpu($|,) ]]; then
                    echo "错误：GPU $gpu 不可用。请重新输入。"
                    valid_input=false
                    break
                fi
            done
            [ "$valid_input" = true ] && break
        else
            echo "无效输入。请输入以逗号分隔的数字。"
        fi
    done

    # 启动挖矿
    for gpu_index in "${gpu_array[@]}"; do
        export CUDA_VISIBLE_DEVICES=$gpu_index
        screen_name="nim_$gpu_index"
        if screen -list | grep -q "$screen_name"; then
            echo "警告：$screen_name 已经在运行。跳过此GPU。"
        else
            screen -dmS "$screen_name" bash -c "make run addr=$wallet_addr master_wallet=$master_wallet_address"
            echo "显卡 $gpu_index 已启动挖矿。/ Mining has started on GPU $gpu_index."
        fi
    done

    echo "挖矿已在选定的GPU上启动。请输入命令 'screen -r nim_<gpu_index>' 查看对应显卡的运行状态。"
    echo "Mining has started on the selected GPUs. Enter 'screen -r nim_<gpu_index>' to view the running status of the corresponding GPU."
}

# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作: /Please select an operation to execute:"
    echo "1. 安装常规节点（附带生成钱包地址） /Install a regular node"
    echo "2. 独立启动挖矿节点 /lonely_start"
    echo "3. 卸载nimble挖矿 /uninstall_node"
    echo "4. 安装挖矿（需要自备钱包） /install_farm"
    echo "5. 多卡挖矿（需要自备钱包） /install_farm"
    read -p "请输入选项（1-4）: Please enter your choice (1-4): " OPTION

    case $OPTION in
    1) install_node ;;
    2) lonely_start ;;
    3) uninstall_node ;;
    4) install_farm ;;
    5) multiple_farm ;;
    *) echo "无效选项。/Invalid option." ;;
    esac
}

main_menu
