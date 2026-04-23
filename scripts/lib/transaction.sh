#!/bin/bash
# トランザクション関連: スロット取得・Tx送信・ハッシュ検証・エアギャップ連携メッセージ

Cli_CurrentSlot(){
  currentSlot=$(cardano-cli query tip $NODE_NETWORK | jq -r '.slot')
}

FilePathAndHash(){
  echo -e "${1} >> ${YELLOW}$(sha256sum "${1}" | awk '{ print $1 }')${NC}"
}

message_file_transfer(){
  echo
  echo "【エアギャップへファイル転送】"
  echo
  echo -e "${YELLOW}1. BPの ${1} をエアギャップのcnodeディレクトリにコピーしてください${NC}"
  echo '----------------------------------------'
  echo -e ">> [BP] ⇒ ${GREEN}${1}${NC}  ⇒ [エアギャップ]"
  echo '----------------------------------------'
  echo
  echo -e "${YELLOW}2. エアギャップ作業${NC}"
  echo '----------------------------------------'
  echo -e "エアギャップで「${GREEN}$2${NC}」コマンドを実行し以下のハッシュ値と一致するか確認してください"
  FilePathAndHash "${NODE_HOME}/${1}"
  echo '----------------------------------------'
  echo
  echo -e "${YELLOW}3. エアギャップの tx.signed をBPのcnodeディレクトリにコピーしてください${NC}"
  echo '----------------------------------------'
  echo -e ">> [エアギャップ] ⇒ ${GREEN}tx.signed${NC} ⇒ [BP]"
  echo '----------------------------------------'
  echo
}

Cli_TxSubmit(){
  while :
  do
    Gum_OneSelect "1～3が完了したらEnterを押して下さい"
    echo
    if [ -f "${NODE_HOME}/tx.signed" ]; then
      FilePathAndHash "${NODE_HOME}/tx.signed"
      echo "上記のハッシュ値とエアギャップに表示されてるハッシュ値と照合してください"
      echo
      if Gum_Confirm "ハッシュ値は一致していますか？"; then
        break 1
      else
        echo "tx.signedを再度エアギャップからコピーしてください"
        Gum_OneSelect "コピーしたらEnterを押して下さい"
        echo
      fi
    else
      echo "tx.signedが見つかりません。正しいディレクトリにコピーしてください"
      echo
      Gum_OneSelect "コピーしたらEnterを押して下さい"
    fi
  done

  echo

  if Gum_Confirm "トランザクションを送信しますか？"; then
    local tx_result=$(cardano-cli conway transaction submit --tx-file "${NODE_HOME}/tx.signed" $NODE_NETWORK)
    echo
    echo '----------------------------------------'
    echo 'Tx送信結果'
    echo '----------------------------------------'
    if [[ -n $tx_result ]]; then
      node_version=$(cardano-node version | head -1 | cut -d' ' -f2)
      if dpkg --compare-versions "$node_version" ge "10.2.1"; then
        tx_id=$(echo $tx_result | jq .txhash | sed 's/"//g')
      else
        tx_id=$(cardano-cli conway transaction txid --tx-body-file "${NODE_HOME}/tx.raw")
        echo $tx_result
      fi
      echo 'TxID:' $tx_id
      echo
      echo 'トランザクションURL'
      if [ ${NODE_CONFIG} == 'mainnet' ]; then
        echo "https://cardanoscan.io/transaction/${tx_id}"
      elif [ ${NODE_CONFIG} == 'preprod' ]; then
        echo "https://preprod.cardanoscan.io/transaction/${tx_id}"
      elif [ ${NODE_CONFIG} == 'preview' ]; then
        echo "https://preview.cardanoscan.io/transaction/${tx_id}"
      else
        echo "TxID:${tx_id}"
      fi
      printf "\n${GREEN}Tx送信に成功しました${NC}\n"
      echo
      printf "\n${YELLOW}Tx承認を確認しています。このまましばらくお待ち下さい...${NC}\n\n"
      local tx_confirm_count=0
      local tx_confirm_limit=180  # 180×10秒 = 30分
      while :
      do
        koios_tx_status=$(curl -s --max-time 10 -X POST "$KOIOS_API/tx_status" \
          -H "Accept: application/json" \
          -H "content-type: application/json" \
          -d "{\"_tx_hashes\":[\"${tx_id}\"]}" | jq -r '.[].num_confirmations // empty')
        if [[ "$koios_tx_status" =~ ^[0-9]+$ ]] && [[ "$koios_tx_status" -gt 1 ]]; then
          printf "確認済みブロック:$koios_tx_status ${GREEN}Txが承認されました${NC}\n\n"
          sleep 3s
          break
        fi
        tx_confirm_count=$((tx_confirm_count + 1))
        if [[ $tx_confirm_count -ge $tx_confirm_limit ]]; then
          printf "${YELLOW}タイムアウト: Cardanoscanで手動確認してください${NC}\n"
          break
        fi
        sleep 10s
      done
      echo
      Gum_OneSelect "戻る"
    else
      echo ${txResult}
      echo
      printf "${RED}Tx送信に失敗しました${NC}\n"
      Gum_OneSelect "戻る"
    fi
  else
    echo
    echo "送信をキャンセルしました"
    echo
    Gum_OneSelect "戻る"
    echo
  fi
}
