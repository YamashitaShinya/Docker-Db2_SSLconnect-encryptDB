# Docker-Db2 暗号通信・透過的暗号データベース作成
IBM Cloud Container Registry(ICR)イメージからSSL通信と透過的暗号DBを設定コンテナ作成  
<span style="color: red; ">***※Db2 Community Edition DockerのイメージはdockerhubからIBM Cloud Container Registry(ICR)へ移行されました***</span>

## 参考
- [dockerhub(ibmcom/db2)](https://hub.docker.com/r/ibmcom/db2)
- [IBMDoc: Linux システムへの Db2 Community Edition Docker イメージのインストール](https://www.ibm.com/docs/ja/db2/12.1?topic=system-linux)


## 前提
- Db2バージョン: latest(最新のバージョン)  
***※バージョン指定したい場合はDockerfileのFROMセクションに記載のタグのバージョンを修正してください***

- WSL2環境のDockerを使用
- Docker for Linux(Community Edition), docker-composeが導入済
- WSL2ログインユーザーがdocker-composeコマンドをroot権限で実行可
- Db2コンテナ作成はカレントディレクトリを`docker-compose.yaml`ファイルがある場所


## 必要ファイル確認
下記ファイルがあること
- Dockerfile
- docker-compose.yaml
- db2.env
- addsslandencryptdb.sh

# Db2コンテナ作成
## コンテナ作成・起動
`<comtainer_name> is up-to-date`が表示されることを確認  
```
sudo docker-compose -f ./docker-compose.yaml up -d
```
## コンテナ作成ログ確認
***※内部でインスタンス作成,DB作成,暗号設定ジョブが動いているので実行ログを確認して完了することを確認***  
```
sudo docker-compose -f ./docker-compose.yaml logs -f
```

# コンテナログイン・設定確認
## Db2インスタンスログイン
```
docker-compose -f ./docker-compose.yaml exec db2 /bin/bash -c "su - tstdbi1"
```

## 環境変数確認
実行コマンド
```
db2set -all
```
下記の通りになってること  
> [i] DB2_DYNAMIC_SSL_LABEL=ON  
> [i] DB2COMM=SSL,TCPIP  
> [g] DB2SYSTEM=<Container_ID>  

## インスタンス設定確認
```
db2 get dbm cfg
```

## 暗号通信設定確認
```
db2 get dbm cfg | grep SSL
```

## DB確認
```
db2 list db directory
```

## DB接続
```
db2 connect to TSTDB
```

## DB設定確認
```
db2 get db cfg for TSTDB
```

## 透過的暗号化確認
`YES`となってること
```
db2 get db cfg for TSTDB | grep "Encrypted database"
```

## 透過的暗号DB マスターキーラベル確認
マスターキーラベルが出力
```
db2 "select * from TABLE(SYSPROC.ADMIN_GET_ENCRYPTION_INFO())"
```

## Db2プロセス切断
```
db2 terminate
```

## Db2コンテナログアウト
```
exit
```

# 補足
適用可能なDb2バージョンはIBM Cloud Container Registry(ICR)CLIを導入しないと確認できないようになっています。  
導入方法は下記リンクをご参照ください。
- [IBM Cloud CLI の概説](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- [IBM Cloud Container Registry CLI](https://cloud.ibm.com/docs/cli?topic=cli-containerregcli)

適用可能なDb2バージョンの確認コマンドは下記
```
ibmcloud cr image-list  --restrict db2_community/db2
```