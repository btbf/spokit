# SPOKIT
<p align="center">
  <a href="https://github.com/btbf/sjg-tools/releases">
    <img src="https://img.shields.io/github/release-pre/btbf/sjg-tools.svg?style=for-the-badge" />
  </a>
  <br>
  <a href=https://spokit.spojapanguild.net/ ><img src="https://github.com/btbf/sjg-tools/blob/main/docs/images/spokit-logo-big.png?raw=true" width=500></a>
</p>
<p align="center">SPOKITはノーコマンドでカルダノステークプールを構築・管理できるCARDANO SPO TOOL KITです！<br>
Linux初級者から上級者までステークプール運営にかかる工数を削減します。</p>



## インストール前の準備
- Ubuntuサーバー(メインネットの場合は最低3台)
- エアギャップマシン
- ターミナルソフト(R-Login/Termius/etc...)
- SFTPソフト(FileZilla/etc...)

## 推奨サーバースペック
項目 | BP/リレー | エアギャプ(ローカル物理PC) |
|-----|-----|-----|
OS | Ubuntu22.04 | Ubuntu22.04
RAM | 24GB以上 | 8GB以上 |
SSD | 500GB以上 | 100GB以上 |

## 1. エアギャップマシンセットアップ

### エアギャップマシン作成

以下手順でローカルPCにUbuntuをインストールする  
[https://docs.spojapanguild.net/setup/air-gap-guid/](https://docs.spojapanguild.net/setup/air-gap-guid/)


### エアギャップ環境設定
以下のコマンドを実行して、エアギャップ環境設定を実施してください。
```
wget -qO- https://raw.githubusercontent.com/btbf/sjg-tools/refs/heads/main/scripts/airgap-setup.sh | bash
```
環境変数再読み込み
```
source $HOME/.bashrc
```

## 2. プール用サーバーセットアップ

### 任意ユーザー作成
```
adduser cardano
```
```
usermod -G sudo cardano
```

### SSH鍵作成
Windowsの場合
```
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
```
```
mkdir ~/.ssh -Force
ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
```
```
cd ~/.ssh
mv ssh_ed25519.pub authorized_keys
```

Macの場合
```
mkdir -p ~/.ssh
ssh-keygen -t ed25519 -N "" -C "ssh_connect" -f ~/.ssh/ssh_ed25519
```
```
cd ~/.ssh
mv ssh_ed25519.pub authorized_keys
```

SSH接続する場合に使用します。
~/.ssh/ssh_ed25519 （秘密鍵）
~/.ssh/authorized_keys （公開鍵）


## 3. SPOKITインストール
安定リリース版
```
wget -qO- https://spokit.spojapanguild.net/install.sh | bash
```

### 環境変数再読み込み
```
source $HOME/.bashrc
```

### 起動
①Ubuntuセキュリティ設定
```
spokit ubuntu
```

②プール構築
```
spokit pool
```

③プール運用
```
spokit
```

## 開発版

```
SPOKIT_MODE=develop bash <(wget -qO- https://raw.githubusercontent.com/btbf/spokit/refs/heads/develop/scripts/install.sh)
```

