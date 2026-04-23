#!/bin/bash
# UI関連: 色定義・スタイル関数・Gumラッパー・ヘッダー表示

#--------------------
# フォアグラウンドカラー
#--------------------
BLACK='\033[0;30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
PURPLE='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'
GRAY='\033[1;30m'

# 太字
B_BLACK='\e[30;1m'
B_RED='\e[31;1m'
B_GREEN='\e[32;1m'
B_YELLOW='\e[33;1m'
B_BLUE='\e[34;1m'
B_PURPLE='\e[35;1m'
B_CYAN='\e[36;1m'
B_WHITE='\e[37;1m'

# 下線
U_BLACK='\e[30;4m'
U_RED='\e[31;4m'
U_GREEN='\e[32;4m'
U_YELLOW='\e[33;4m'
U_BLUE='\e[34;4m'
U_PURPLE='\e[35;4m'
U_CYAN='\e[36;4m'
U_WHITE='\e[37;4m'

# 点滅
F_BLACK='\e[30;5m'
F_RED='\e[31;5m'
F_GREEN='\e[32;5m'
F_YELLOW='\e[33;5m'
F_BLUE='\e[34;5m'
F_PURPLE='\e[35;5m'
F_CYAN='\e[36;5m'
F_WHITE='\e[37;5m'

# リセット
NC='\033[0m'

#--------------------
# スタイル関数
#--------------------

# 2列ラベル表示（白背景ラベル + 黄色値）
style(){
  printf '{{ Color "15" "'"$1"'" }}''{{ Color "11" " '"$2"' " }}' | gum format -t template; echo
}

# 色番号を指定してテキストを表示する基底関数
ColorStyle(){
  printf '{{ Color "'"$1"'" "'"$2"'" }}' | gum format -t template; echo
}

YellowStyle()  { ColorStyle "11"  "$1"; }
MagentaStyle() { ColorStyle "127" "$1"; }
PinkStyle()    { ColorStyle "127" "$1"; }
GreenStyle()   { ColorStyle "2"   "$1"; }
CyanStyle()    { ColorStyle "6"   "$1"; }
LglayStyle()   { ColorStyle "249" "$1"; }
DglayStyle()   { ColorStyle "242" "$1"; }
ErrorStyle()   { ColorStyle "196" "$1"; }

#--------------------
# Gumラッパー関数
#--------------------

Gum_DotSpinner3(){
  gum spin --spinner dot --title "${1}" -- sleep 3
}

Gum_DotSpinner(){
  gum spin --spinner dot --title "${1}" -- ${2}
}

Gum_Fnspin(){
  local TITLE="${*: -1}"
  local COMMANDO="${*:1:$(($# - 1))}"
  gum spin --spinner="dot" --title="$TITLE" --show-output -- bash -c "source ../spokit.library && $COMMANDO"
}

Gum_OneSelect(){
  echo
  gum choose --header.foreground="244" --header="" --height=1 --no-show-help "${1}"
  return
}

Gum_Confirm_YesNo(){
  gum confirm "${1}" --default=true --affirmative="はい" --negative="いいえ" --no-show-help && iniSettings="${2}" || iniSettings="${3}"
  echo
}

#--------------------
# ヘッダー表示
#--------------------

Header(){
  echo -e "${CYAN}"
  color_text="${YELLOW}${1}${NC}"
  plain_text="${1}"

  width=20
  pad=$((width - ${#plain_text}))
  cat << "EOF"
  ███████╗██████╗  ██████╗ ██╗  ██╗██╗████████╗
  ██╔════╝██╔══██╗██╔═══██╗██║ ██╔╝██║╚══██╔══╝
  ███████╗██████╔╝██║   ██║█████╔╝ ██║   ██║
  ╚════██║██╔═══╝ ██║   ██║██╔═██╗ ██║   ██║
  ███████║██║     ╚██████╔╝██║  ██╗██║   ██║
  ╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝
EOF
  echo -e "${NC}"
  echo -e "           ${CYAN}Cardano SPO Tool Kit${NC} ${GREEN}v${version}${NC}         "
  echo
  echo -e "${YELLOW}ネットワーク:${NC} ${NODE_CONFIG}"
  echo -e "${YELLOW}ノードタイプ:${NC} ${NODE_TYPE}"
  echo
  echo -e "${WHITE}----------------------------------------------------${NC}"
  printf "%*s%b\n" "$pad" "" "$color_text"
  echo -e "${WHITE}----------------------------------------------------${NC}"
}
