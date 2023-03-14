# Docker-Db2_SSLconnect-encryptDB
DockerHubイメージからSSL通信と透過的暗号DBを設定コンテナ作成

#Docker Hub URL: https://hub.docker.com/r/ibmcom/db2
#Db2バージョン: V11.5.6.0(v11.5 Mod6FP0)
#※バージョン変更したい場合はDockerfileのFROMセクションに記載のタグのバージョンを修正してください
#　指定できるバージョンは上記Hub URLを参照
#前提:
#・WSL2環境のDockerを使用
#・Docker for Linux(Community Edition), docker-composeが導入済である
#・WSL2ログインユーザーがdocker-composeコマンドをroot権限で実行できる
#・docker-compose.yamlファイルがカレントディレクトリ(移動済)である

#下記ファイルがあること
# Dockerfile
# docker-compose.yaml
# db2.env
ls -ltr

##image構築
# "Creating <comtainer_name> ... done"が最後に表示されることを確認
sudo docker-compose -f ./docker-compose.yaml up -d --build

##コンテナ作成・起動
# "<comtainer_name> is up-to-date"が表示されることを確認
sudo docker-compose -f ./docker-compose.yaml up -d

##コンテナ作成ログ確認
# ※内部でインスタンス作成,DB作成,暗号設定ジョブが動いているので実行ログを確認して完了することを確認
sudo docker-compose -f ./docker-compose.yaml logs -f

##Db2インスタンスログイン
docker-compose -f ./docker-compose.yaml exec db2 /bin/bash -c "su - tstdbi1"

##環境変数確認
#下記の通りになってること
# [i] DB2_DYNAMIC_SSL_LABEL=ON
# [i] DB2COMM=SSL,TCPIP
# [g] DB2SYSTEM=<Container_ID>
db2set -all

##インスタンス設定確認
db2 get dbm cfg

##暗号通信設定確認
db2 get dbm cfg | grep SSL

#DB確認
db2 list db directory

#DB接続
db2 connect to TSTDB

##DB設定確認
db2 get db cfg for TSTDB

##透過的暗号化確認
# "YES"となってること
db2 get db cfg for TSTDB | grep "Encrypted database"

#テーブル内にデータ(設定情報)があること
db2 "select * from TABLE(SYSPROC.ADMIN_GET_ENCRYPTION_INFO())"

#DBプロセス切断
db2 terminate

##Db2インスタンスログアウト
exit
