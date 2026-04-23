#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"

source ${HOME}/.bashrc
source ${SPOKIT_INST_DIR}/spokit.library
source ${SPOKIT_INST_DIR}/components/node_install
source ${SPOKIT_INST_DIR}/components/grafana_install
source ${SPOKIT_INST_DIR}/components/create_metadata
source ${SPOKIT_INST_DIR}/components/register_pool
source ${SPOKIT_INST_DIR}/components/create_pool_keys
source ${SPOKIT_INST_DIR}/components/topology_management
source ${SPOKIT_INST_DIR}/components/check_poolwallet
source ${SPOKIT_INST_DIR}/components/air_gap
source ${SPOKIT_INST_DIR}/components/manage_wallet
source ${SPOKIT_INST_DIR}/components/manage_pool
source ${SPOKIT_INST_DIR}/components/node_sync_check
source ${SPOKIT_INST_DIR}/components/mithril_bootstrap
source ${SPOKIT_INST_DIR}/components/governance
source ${SPOKIT_INST_DIR}/components/blocklog_setup
source ${SPOKIT_INST_DIR}/components/node_update
source ${env_path}

clear

#-------------------------------#
 #Spokitプール構築メニュー
#-------------------------------#

PoolSetupMenu(){
  headerTitle="プール構築メニュー"

  case $NODE_TYPE in
    "ブロックプロデューサー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ノードインストール" "[2] トポロジー設定" "[3] プール運用キー作成" "[4] ウォレット入金" "[5] ステークアドレス登録" "[6] プールメタデータ作成" "[7] プール登録" "[8] 監視ツールセットアップ" "[9] ブロックログインストール" "[q] 終了")
      case $selection in
        "[1] ノードインストール" )
            NodeInstall
        ;;

        "[2] トポロジー設定" )
            topologyManagement
        ;;

        "[3] プール運用キー作成" )
            create_pool_keys
        ;;

        "[4] ウォレット入金" )
            checkPoolwallet
        ;;

        "[5] ステークアドレス登録" )
            registerStakeadd
        ;;

        "[6] プールメタデータ作成" )
            createMetadata
        ;;

        "[7] プール登録" )
            registerPool "new"
        ;;

        "[8] 監視ツールセットアップ" )
            prometheusInstall
        ;;

        "[9] ブロックログインストール" )
            BlocklogFullSetup
        ;;

        "[q] 終了" )
          tmux kill-session -t spokit
        ;;
      esac
      done
    ;;

    "リレー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ノードインストール" "[2] トポロジー設定" "[3] 監視ツールセットアップ" "[q] 終了")
      case $selection in
        "[1] ノードインストール" )
            NodeInstall
        ;;

        "[2] トポロジー設定" )
            topologyManagement
        ;;

        "[3] 監視ツールセットアップ" )
            grafanaInstall
        ;;

        "[q] 終了" )
          tmux kill-session -t spokit
        ;;
      esac
      done
    ;;

  esac
}


#-------------------------------#
 #Spokitプール管理メニュー
#-------------------------------#
CnmMain(){
  headerTitle="プール管理メニュー"
  case $NODE_TYPE in
    "ブロックプロデューサー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=12 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] ウォレット管理" "[2] プール情報管理" "[3] ガバナンス管理" "[4] ブロックログ管理" "[5] ノードアップデート" "[q] 終了")
      case $selection in
        "[1] ウォレット管理" )
        manageWallet
        ;;

        "[2] プール情報管理" )
        managePool
        ;;

        "[3] ガバナンス管理" )
        GovernanceMenu
        ;;

        "[4] ブロックログ管理" )
        BlocklogMenu
        ;;

        "[5] ノードアップデート" )
        NodeUpdate
        ;;

        "[q] 終了" )
          tmux kill-session -t spokit
        ;;
      esac
      done
    ;;
    
    "リレー" )
      while :
      do
      clear
      Header $headerTitle
      selection=$(gum filter --height=6 --no-show-help --header.foreground="075" --indicator=">" --placeholder="番号選択も可..." --prompt="◉ " "[1] トポロジー変更" "[2] ノードアップデート" "[q] 終了")
      case $selection in
        "[1] トポロジー変更" )
            topologyManagement
        ;;

        "[2] ノードアップデート" )
            NodeUpdate
        ;;

        "[q] 終了" )
          tmux kill-session -t spokit
        ;;
      esac
      done
    ;;
  esac
}


clear
#env再読み込み
source ${env_path}

if [[ -z "$1" || "$1" == "pool" ]]; then
  SpokitUpdateCheck
fi

case $1 in
  "ubuntu" )
    source ${SPOKIT_INST_DIR}/components/ubuntu_setup
    UbuntuSetup
    tmux kill-session -t spokit
  ;;

  "pool" )
    PoolSetupMenu
  ;;

  "" )
    CnmMain
  ;;
esac
