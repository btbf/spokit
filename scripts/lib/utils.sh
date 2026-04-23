#!/bin/bash
# 汎用ユーティリティ: 変数チェック・sudo・アップデート・プールデータ・ポート選択など

#--------------------
# 変数・パスチェック
#--------------------

VariableEnabledCheck(){
  if [ -n "${1}" ]; then
    echo "${2}"
  else
    echo "${3}"
  fi
}

PathEnabledCheck(){
  if [ -f "${1}" ]; then
    echo -e "${2}"
  else
    echo -e "${3}"
  fi
}

#--------------------
# sudo パスワード
#--------------------

InputSudoPass(){
  if sudo -n true 2>/dev/null; then
    echo ""
  else
    gum input --password --no-show-help --placeholder="sudoパスワードを入力してください"
  fi
}

UfwCheck(){
  sudopass=$(InputSudoPass)
  echo "$sudopass" | sudo -S ufw status | awk '/Status/ {print $2}'
}

#--------------------
# システム管理
#--------------------

SystemUpdate(){
  LglayStyle "Ubuntuパッケージアップデート開始..."
  sudopass=$(InputSudoPass)
  echo "$sudopass" | sudo -S apt update -y && sudo apt upgrade -y
  echo
  DglayStyle "Ubuntuパッケージアップデート完了"
  sleep 3
}

Installdependencies(){
  sudo apt install git nano jq bc automake tmux rsync htop curl build-essential \
    pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev \
    zlib1g-dev make g++ wget libncursesw5 libtool autoconf liblmdb-dev ccze \
    -y > /dev/null 2>&1
}

#--------------------
# SPOKITアップデート確認
#--------------------

SpokitUpdateCheck(){
  latest_version=$(curl -s https://api.github.com/repos/btbf/spokit/releases/latest | jq -r '.tag_name')

  if [ "$(printf '%s\n' "$latest_version" "$version" | sort -V | head -n1)" != "$version" ]; then
    echo
    echo -e "${YELLOW}新しいバージョンが利用可能です: ${GREEN}${latest_version}${NC}"
    echo -e "${YELLOW}最新バージョンにアップデートしてください${NC}"
    echo
    if Gum_Confirm "spokitをアップデートしますか？"; then
      clear
      echo -e "${YELLOW}spokitをアップデートしています...${NC}"
      base_url="https://github.com/btbf/spokit/archive/refs/tags/${spokit_version}.tar.gz"
      wget -q "${base_url}" -O "$HOME/spokit.tar.gz"
      if [ $? -ne 0 ]; then
        echo -e "${RED}SPOKITのダウンロードに失敗しました。インターネット接続を確認してください。${NC}"
        rm -f "$HOME/spokit.tar.gz"
        exit 1
      fi
      if ! gzip -t "$HOME/spokit.tar.gz" 2>/dev/null; then
        echo -e "${RED}ダウンロードファイルが破損しています。再度お試しください。${NC}"
        rm -f "$HOME/spokit.tar.gz"
        exit 1
      fi
      tar -xzf "$HOME/spokit.tar.gz"
      if [ $? -ne 0 ]; then
        echo -e "${RED}SPOKITの解凍に失敗しました。${NC}"
        exit 1
      fi
      rm spokit.tar.gz
      cd "spokit-${spokit_version}/scripts" || exit 1
      sudo cp -pR ./* "${SPOKIT_INST_DIR}"
      chmod 755 "${SPOKIT_INST_DIR}/spokit_run.sh"
      chmod 755 "${SPOKIT_INST_DIR}/spokit.sh"
      printf "${YELLOW}SPOKITをインストールしました${NC}\n"
      rm -rf "$HOME/git/spokit-${spokit_version}"
    fi
  fi
}

#--------------------
# ファイル生成
#--------------------

CreatePoolMetaJson(){
  cat <<-EOF > "${NODE_HOME}/${5}"
{
  "name": "$1",
  "description": "$2",
  "ticker": "$3",
  "homepage": "$4"
}
EOF
}

#--------------------
# ADAハンドル変換
#--------------------

adahandleConvert(){
  adahandlePolicyID="f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"
  assetNameHex=$(echo -n "${1}" | xxd -b -ps -c 80 | tr -d '\n')
  if [[ $NODE_CONFIG != "mainnet" ]]; then
    assetNameHex="000de140${assetNameHex}"
  fi
  curl -s -X GET \
    "$KOIOS_API/asset_addresses?_asset_policy=${adahandlePolicyID}&_asset_name=${assetNameHex}" \
    -H "Accept: application/json" | jq -r '.[].payment_address'
}

#--------------------
# プールデータ取得
#--------------------

get_pooldata(){
  pId_json="{\"_pool_bech32_ids\":[\"$(cat "$NODE_HOME/$POOL_ID_BECH32_FILENAME")\"]}"
  curl -s -X POST "$KOIOS_API/pool_info" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$pId_json" > "$NODE_HOME/pooldata.txt"
  wait

  pooldata_chk=$(cat "$NODE_HOME/pooldata.txt")
  if [[ $pooldata_chk != *"pool_id_bech32"* ]]; then
    echo "APIからプールデータを取得できませんでした。再度お試しください"
    Gum_OneSelect "戻る"
  fi
}

#--------------------
# ポート番号選択
#--------------------

select_port(){
  case $1 in
    "node" )
      local min_range=49152
      local max_range=57343
      case $NODE_TYPE in
        "ブロックプロデューサー" )
          local loop_count=5
          local header="ブロックプロデューサー起動に使用する任意のポートを設定してください"
          port_set=""
        ;;
        "リレー" )
          local loop_count=3
          local header="リレーノード起動に使用する任意のポートを設定してください"
          port_set="6000 6001"
        ;;
      esac
      ;;
    "ssh" )
      local min_range=57344
      local max_range=65535
      local loop_count=5
      local header="SSHに使用する任意のポートを設定してください"
      port_set=""
      ;;
  esac

  for i in $(seq 1 $loop_count); do
    port_set="$port_set $(($min_range + RANDOM % ($max_range - $min_range + 1)))"
  done
  port_set="$port_set カスタム"

  port_number=$(gum choose --header.foreground="244" --header="${header}" --no-show-help $port_set)
  if [[ $port_number == "カスタム" ]]; then
    while :
    do
      port_number=$(gum input --char-limit=5 --no-show-help --placeholder="任意のポート番号を入力してください")
      if [[ $port_number =~ ^[0-9]+$ ]]; then
        break
      else
        echo
        echo "整数を入力してください"
        echo
        sleep 2
      fi
    done
  fi
  echo $port_number
}
