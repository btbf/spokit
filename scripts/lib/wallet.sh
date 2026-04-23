#!/bin/bash
# ウォレット関連: 残高照会・Lovelace変換・手数料計算・出金表示

#--------------------
# Lovelace変換
#--------------------

scale1(){
  echo "scale=6; $1 / 1000000" | bc
}

scale3(){
  echo "scale=6; $1 / 1000000" | bc | awk '{printf "%.5f\n", $0}'
}

#--------------------
# 残高照会
#--------------------

WalletBalance(){
  tx_in=""
  total_balance=0
  while read -r utxo; do
    in_addr=$(awk '{ print $1 }' <<< "${utxo}")
    idx=$(awk '{ print $2 }' <<< "${utxo}")
    utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
    total_balance=$((${total_balance}+${utxo_balance}))
    tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
  done < "${NODE_HOME}/balance.out"
  txcnt=$(wc -l < "${NODE_HOME}/balance.out")
  style "ADA残高:" "$(scale1 ${total_balance})"
}

CheckWallet(){
  echo "アドレス:"
  YellowStyle "$(cat "${NODE_HOME}/${PAYMENT_ADDR_FILENAME}")"
  gum spin --spinner dot --show-output --title "ウォレット残高を確認しています" -- \
    cardano-cli conway query utxo \
      --address "$(cat "${NODE_HOME}/${PAYMENT_ADDR_FILENAME}")" \
      $NODE_NETWORK --output-text \
      --out-file "${NODE_HOME}/fullUtxo.out"
  tail -n +3 "${NODE_HOME}/fullUtxo.out" | sort -k3 -nr > "${NODE_HOME}/balance.out"
  echo
  WalletBalance
  echo
  echo "UTXO一覧"
  LglayStyle "$(cat "${NODE_HOME}/balance.out")"
}

reward_Balance(){
  if [[ -e "${NODE_HOME}/${STAKE_ADDR_FILENAME}" ]]; then
    echo "■stakeアドレス"
    printf "${YELLOW}$(cat "${NODE_HOME}/$STAKE_ADDR_FILENAME")${NC}\n\n"
    pool_reward=$(cardano-cli conway query stake-address-info \
      --address "$(cat "${NODE_HOME}/${STAKE_ADDR_FILENAME}")" \
      $NODE_NETWORK | jq .[].rewardAccountBalance)
    if [[ -n ${pool_reward} ]]; then
      pool_reward_Amount=$(scale1 ${pool_reward})
      printf "報酬額:${GREEN}%s${NC} ADA (%s Lovelace)\n" "${pool_reward_Amount}" "${pool_reward}"
      Gum_OneSelect "戻る"
    else
      echo "報酬はまだ発生していません"
      Gum_OneSelect "戻る"
    fi
  else
    echo "${STAKE_ADDR_FILENAME}ファイルが見つかりません"
    echo
    echo "${NODE_HOME}に${STAKE_ADDR_FILENAME}をコピーするか"
    echo "envファイルのSTAKE_ADDR_FILENAME変数の指定値をご確認ください"
    echo
    Gum_OneSelect "戻る"
  fi
}

#--------------------
# 手数料計算・出金確認表示
#--------------------

Cli_FeeCal(){
  fee=$(cardano-cli conway transaction calculate-min-fee \
    --tx-body-file "${NODE_HOME}/tx.tmp" \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    $NODE_NETWORK \
    --witness-count 2 \
    --byron-witness-count 0 \
    --output-text \
    --protocol-params-file "${NODE_HOME}/params.json" | awk '{ print $1 }')
  echo "fee: $fee"
  echo
}

tx_Check(){
  printf "%-8s : ${YELLOW}%-15s${NC}\n" "送金先" "$1"
  printf "%-8s : ${GREEN}%-15s${NC}\n" "送金額" "$(scale1 $2) ADA"
  printf "%-8s : ${GREEN}%-15s${NC}\n" "手数料" "$(scale3 $3) ADA"
  printf "%-8s : ${GREEN}%-15s${NC}\n" "残高額" "$(scale1 $4) ADA"
}
