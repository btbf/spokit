#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"
# shellcheck source="${env_path}"

clear

SPOKIT_INST_DIR=/opt/spokit
SPOKIT_HOME=$HOME/spokit
gum_version="0.16.2"
spokit_version=""

source ${HOME}/.bashrc


style(){
  echo -e '{{ Color "15" " '"$1"' " }}''{{ Color "11" " '"$2"' " }}' "\n" | gum format -t template; echo
}


create_env_file(){
mkdir -p ${SPOKIT_HOME}
cat <<-EOF > ${SPOKIT_HOME}/env
#!/bin/bash
#主要な値は環境変数に入っています。 "${HOME}"/.bashrc

NODE_TYPE="${1}"
SYNC_NETWORK="${2}"
COLDKEYS_DIR='\${HOME}/cold-keys'
COLD_SKEY_FILENAME="node.skey"
COLD_VKEY_FILENAME="node.vkey"
COUNTER_FILENAME="node.counter"
KES_SKEY_FILENAME="kes.skey"
KES_VKEY_FILENAME="kes.vkey"
VRF_SKEY_FILENAME="vrf.skey"
VRF_VKEY_FILENAME="vrf.vkey"
NODE_CERT_FILENAME="node.cert"
POOL_CERT_FILENAME="pool.cert"
PAYMENT_SKEY_FILENAME="payment.skey"
PAYMENT_VKEY_FILENAME="payment.vkey"
PAYMENT_ADDR_FILENAME="payment.addr"
STAKE_SKEY_FILENAME="stake.skey"
STAKE_VKEY_FILENAME="stake.vkey"
STAKE_ADDR_FILENAME="stake.addr"
STAKE_CERT_FILENAME="stake.cert"
POOL_META_FILENAME="poolMetaData.json"
POOL_ID_FILENAME="pool.id"
POOL_ID_BECH32_FILENAME="pool.id-bech32"
KOIOS_API="${4}"
NODE_PROMETHEUS_PORT="12798"
UFW_STATUS="${3}"
EOF
}


DotSpinner3(){
    gum spin --spinner dot --title "${1}" -- sleep 3
}


view_title_logo(){
    echo -e "${CYAN}"
    cat << "EOF"
███████╗██████╗  ██████╗ ██╗  ██╗██╗████████╗
██╔════╝██╔══██╗██╔═══██╗██║ ██╔╝██║╚══██╔══╝
███████╗██████╔╝██║   ██║█████╔╝ ██║   ██║   
╚════██║██╔═══╝ ██║   ██║██╔═██╗ ██║   ██║   
███████║██║     ╚██████╔╝██║  ██╗██║   ██║   
╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝ 
EOF
    echo -e "${GREEN}                   ${1}                     ${NC}"
    echo -e "${WHITE}============================================${NC}"
    echo -e "${CYAN}           Cardano SPO Tool Kit              ${NC}"
    echo -e "${YELLOW}         ${2}                           ${NC}"
    echo -e "${WHITE}============================================${NC}"
}

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\e[36m'
PURPLE='\e[35m'
YELLOW='\e[33m'
BLUE='\e[34m'
WHITE='\e[37m'
BOLD='\e[1m'
UNDERLINE='\e[4m'
NC='\033[0m' # No Color

##############
#起動タイトル
##############

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}rootユーザーでは実行できません${NC}"
    echo "一般ユーザーで再度実行してください"
    exit 1
fi

if [[ ! -d $SPOKIT_INST_DIR ]]; then
#環境設定
cat > ~/.tmux.conf << EOF
set -g default-terminal "screen-256color"
EOF
    view_title_logo "${spokit_version}" "ライブラリインストール"
    #ライブラリインストール
    printf "管理者(sudo)パスワードを入力してください\n"
    echo
    sudo apt update && sudo apt upgrade -y
    sudo apt install jq curl wget -y
    if [ ! -f "/usr/bin/gum" ]; then
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
        sudo apt update && sudo apt install gum=${gum_version} -y
    fi
    sudo apt-mark hold gum
    echo -e "${GREEN}関連ライブラリをインストールしました${NC}"
else
    echo -e ${YELLOW}"Spokitはすでにインストールされています${NC}"
    echo -e "${GREEN}spokit${NC} または ${GREEN}spokit pool${NC} で起動するかご確認ください"
    echo
    read -p "インストールを終了するにはEnterキーを押してください..."
fi


##------初期設定
clear
if [ ! -d "${SPOKIT_HOME}" ]; then
    view_title_logo "${spokit_version}" "ノードセットアップ初期設定"

    if [ -d "${NODE_HOME}" ]; then 
        echo -e "既存のネットワーク設定が見つかりました : ${NODE_CONFIG}\n"
        work_dir=${NODE_HOME}
        sync_network=${NODE_CONFIG}
    else
        NODE_TYPE=$(gum choose --header.foreground="244" --header="セットアップノードタイプを選択して下さい" "ブロックプロデューサー" "リレー" --no-show-help)
        sync_network=$(gum choose --header.foreground="244" --header="接続ネットワークを選択してください" --no-show-help "Mainnet" "Preview-Testnet" "Preprod-Testnet")
        work_dir=$(gum input --value "${HOME}/cnode" --width=0 --no-show-help --header.foreground="244" --header="プール作業ディレクトリを作成します。デフォルトの場合はそのままEnterを押して下さい" --header.foreground="99" --placeholder "${HOME}/cnode")
    fi

        # ufw確認
    UFW_STATUS=$(sudo ufw status | grep -i "Status:" | awk '{print $2}')
    if [ "${UFW_STATUS}" != "active" ]; then
        echo -e "${YELLOW}UFW(内部ファイアウォール)が無効になっています。${NC}"
        UFW_STATUS="disabled"
    else
        echo -e "${GREEN}UFW(内部ファイアウォール)は有効になっています${NC}"
        UFW_STATUS="enabled"
        sleep 1
    fi

    #Spokitインストール
    
    printf "${YELLOW}SPOKITをインストール...${NC}\n"
    mkdir -p "$HOME/git"
    cd "$HOME/git" || exit 1

    if [[ "$SPOKIT_MODE" == "develop" ]]; then
        echo "🧪 SPOKIT Develop Mode"
        base_url="https://github.com/btbf/spokit/raw/refs/heads/develop/dist/spokit-develop.tar.gz"
    else
        echo "🚀 SPOKIT Release Mode"
        base_url="https://github.com/btbf/spokit/archive/refs/tags/${spokit_version}.tar.gz"
    fi

    wget -q ${base_url} -O spokit.tar.gz

    if [ $? -ne 0 ]; then
        echo -e "${RED}SPOKITのダウンロードに失敗しました。インターネット接続を確認してください。${NC}"
        rm -f spokit.tar.gz
        exit 1
    fi
    if ! gzip -t spokit.tar.gz 2>/dev/null; then
        echo -e "${RED}ダウンロードファイルが破損しています。再度お試しください。${NC}"
        rm -f spokit.tar.gz
        exit 1
    fi
    tar -xzf spokit.tar.gz
    if [ $? -ne 0 ]; then
        echo -e "${RED}SPOKITの解凍に失敗しました。${NC}"
        exit 1
    fi
    rm spokit.tar.gz
    sudo mkdir -p ${SPOKIT_INST_DIR}
    cd "spokit-${spokit_version}/scripts" || exit 1
    sudo cp -pR ./* ${SPOKIT_INST_DIR}

    chmod 755 ${SPOKIT_INST_DIR}/spokit_run.sh
    chmod 755 ${SPOKIT_INST_DIR}/spokit.sh

    printf "${YELLOW}SPOKITをインストールしました${NC}\n"
    rm -rf $HOME/git/spokit-${spokit_version}

    echo
    case "${sync_network}" in
        "Mainnet" )
            NODE_CONFIG=mainnet
            NODE_NETWORK='"--mainnet"'
            CARDANO_NODE_NETWORK_ID=mainnet
            KOIOS_DOMAIN="https://api.koios.rest/api/v1"
        ;;
        "Preview-Testnet" )
            NODE_CONFIG=preview
            NODE_NETWORK='"--testnet-magic 2"'
            CARDANO_NODE_NETWORK_ID=2
            KOIOS_DOMAIN="https://preview.koios.rest/api/v1"
        ;;
        "Preprod-Testnet" )
            NODE_CONFIG=preprod
            NODE_NETWORK='"--testnet-magic 1"'
            CARDANO_NODE_NETWORK_ID=1
            KOIOS_DOMAIN="https://preprod.koios.rest/api/v1"
        ;;
    esac

    style "ノードタイプ:" "${NODE_TYPE}"
    style "ネットワーク:" "${sync_network}"
    style "作業ディレクトリ:" "${work_dir}"
    style "UFWステータス:" "${UFW_STATUS}"
    echo
    if gum confirm "この設定でよろしいですか？" --default=true --no-show-help --affirmative="はい" --negative="いいえ"; then
        if [ ! -d "$NODE_HOME" ]; then
            echo "環境変数を追加します"
            echo PATH="$HOME/.local/bin:$PATH" >> "${HOME}"/.bashrc
            echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> "${HOME}"/.bashrc
            echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> "${HOME}"/.bashrc
            echo export NODE_HOME="${work_dir}" >> "${HOME}"/.bashrc
            echo export NODE_CONFIG="${NODE_CONFIG}" >> "${HOME}"/.bashrc
            echo export NODE_NETWORK="${NODE_NETWORK}" >> "${HOME}"/.bashrc
            echo export CARDANO_NODE_NETWORK_ID="${CARDANO_NODE_NETWORK_ID}" >> "${HOME}"/.bashrc
            echo export CARDANO_NODE_SOCKET_PATH="${work_dir}/db/socket" >> "${HOME}"/.bashrc
            echo export SPOKIT_INST_DIR="${SPOKIT_INST_DIR}" >> "${HOME}"/.bashrc
            echo export SPOKIT_HOME="${SPOKIT_HOME}" >> "${HOME}"/.bashrc
            echo alias spokit="'${SPOKIT_INST_DIR}/spokit_run.sh'" >> "${HOME}"/.bashrc
            echo alias cnode='"sudo journalctl -u cardano-node -f --output=cat | ccze -A"' >> "${HOME}"/.bashrc
            echo alias cnstart='"sudo systemctl start cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnrestart='"sudo systemctl reload-or-restart cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnstop='"sudo systemctl stop cardano-node"' >> "${HOME}"/.bashrc
            echo alias cnreload='"pkill -HUP cardano-node"' >> "${HOME}"/.bashrc
            echo alias glive="'cd ${work_dir}/scripts; ./gLiveView.sh'" >> "${HOME}"/.bashrc
        else
            echo export SPOKIT_INST_DIR="${SPOKIT_INST_DIR}" >> "${HOME}"/.bashrc
            echo export SPOKIT_HOME="${SPOKIT_HOME}" >> "${HOME}"/.bashrc
            echo alias spokit="'${SPOKIT_INST_DIR}/spokit_run.sh'" >> "${HOME}"/.bashrc
        fi


        #設定ファイル作成
        create_env_file "${NODE_TYPE}" "${NODE_CONFIG}" "${UFW_STATUS}" "${KOIOS_DOMAIN}"

        echo
        style "設定ファイルを作成しました" "${SPOKIT_HOME}/env"
        echo

        DotSpinner3 "初期設定を終了します"
        echo
        echo -e "${RED}①下記コマンドを実行して環境変数を再読み込みしてください${NC}"
        echo "------------------------"
        echo "source $HOME/.bashrc"
        echo "------------------------"
        echo
        echo -e "${YELLOW}①Ubuntuセキュリティ設定${NC}"
        echo "------------------------"
        echo -e "${GREEN}spokit ubuntu${NC}"
        echo "------------------------"
        echo
        echo -e "${YELLOW}②プール構築${NC}"
        echo "------------------------"
        echo -e "${GREEN}spokit pool${NC}"
        echo "------------------------"
        echo
        echo -e "${YELLOW}②プール運用${NC}"
        echo "------------------------"
        echo -e "${GREEN}spokit${NC}"
        echo "------------------------"
        echo
    else
        clear
        echo
        echo "最初からやり直す場合はツールを再実行してください"
        exit
    fi

else
    echo -e ${YELLOW}"Spokitはすでにインストールされています${NC}"
    echo -e "${GREEN}spokit${NC} または ${GREEN}spokit pool${NC} で起動するかご確認ください"
    echo
    read -p "インストールを終了するにはEnterキーを押してください..."

fi
