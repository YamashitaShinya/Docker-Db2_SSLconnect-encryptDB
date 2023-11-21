#!/bin/bash

#DB名設定(db2.envにて指定をし、自動作成する場合はコメントアウト)
DBNAME=TSTDB

#暗号通信ポート設定
cp /etc/services /etc/services.db2ssl
echo "db2s_${DB2INSTANCE}      50100/tcp" >> /etc/services

#インスタンスプロファイル読み込み
. /database/config/${DB2INSTANCE}/sqllib/db2profile

#キーストア作成
mkdir -m 770 /database/.keys
chgrp db2iadm1 /database/.keys
export KEYSTOREPASS=$(/opt/ibm/db2/V11.5/gskit/bin/gsk8capicmd_64 -random -create -length 16 -strong)
echo ${KEYSTOREPASS} > /database/.keys/KeyStore.pass
/opt/ibm/db2/V11.5/gskit/bin/gsk8capicmd_64 -keydb -create -db /database/.keys/KeyStore.p12 -type pkcs12 -pw "${KEYSTOREPASS}" -stash
chmod 660 /database/.keys/KeyStore.p12 /database/.keys/KeyStore.sth
chgrp db2iadm1 /database/.keys/KeyStore.p12 /database/.keys/KeyStore.sth

#暗号通信証明書作成
/opt/ibm/db2/V11.5/gskit/bin/gsk8capicmd_64 -cert -create -db /database/.keys/KeyStore.p12 -stashed -label "$(uname -n)_cert_$(date +%Y%m%d)" -dn "CN=$(uname -n),OU=test,O=test,L=Minato,ST=Tokyo,C=JP -expire 730 -size 4096 -sigalg SHA512WithRSA"

#Db2環境変数設定

su - ${DB2INSTANCE} << EOF
db2set -all
db2set DB2COMM=SSL,TCPIP
db2set DB2_DYNAMIC_SSL_LABEL=ON -immediate
db2set -all
EOF

#DBM設定
db2 "attach to ${DB2INSTANCE} user ${DB2INSTANCE} using ${DB2INST1_PASSWORD}"
db2 "get dbm cfg" | grep -i DIAGLEVEL
db2 "update dbm cfg using DIAGLEVEL 4"
db2 "get dbm cfg" | grep -i DIAGLEVEL
db2 "get dbm cfg" | grep -i KEYSTORE_LOCATION
db2 "update dbm cfg using KEYSTORE_LOCATION /database/.keys/KeyStore.p12"
db2 "get dbm cfg" | grep -i KEYSTORE_LOCATION
db2 "get dbm cfg" | grep -i KEYSTORE_TYPE
db2 "update dbm cfg using KEYSTORE_TYPE PKCS12"
db2 "get dbm cfg" | grep -i SSL_VERSIONS
#db2 "update dbm cfg using SSL_VERSIONS TLSV12"
# TLSv1.3はMod8から設定可
db2 "update dbm cfg using SSL_VERSIONS TLSV12,TLSV13"
db2 "get dbm cfg" | grep -i SSL_VERSIONS
db2 "get dbm cfg" | grep -i SSL_SVR_KEYDB
db2 "update dbm cfg using SSL_SVR_KEYDB /database/.keys/KeyStore.p12"
db2 "get dbm cfg" | grep -i SSL_SVR_KEYDB
db2 "get dbm cfg" | grep -i SSL_SVR_STASH
db2 "update dbm cfg using SSL_SVR_STASH /database/.keys/KeyStore.sth"
db2 "get dbm cfg" | grep -i SSL_SVR_STASH
db2 "get dbm cfg" | grep -i SSL_SVR_LABEL
db2 "update dbm cfg using SSL_SVR_LABEL $(uname -n)_cert_$(date +%Y%m%d)"
db2 "get dbm cfg" | grep -i SSL_SVR_LABEL
db2 "get dbm cfg" | grep -i SSL_SVCENAME
db2 "update dbm cfg using SSL_SVCENAME db2s_${DB2INSTANCE}"
db2 "get dbm cfg" | grep -i SSL_SVCENAME
db2 "detach"

#Db2インスタンス再起動
su - ${DB2INSTANCE} -c "db2stop;ipclean;db2start"

#DB透過的暗号化(自動作成されたDBを透過的暗号リストアする場合コメントアウトを外すこと)
# su - ${DB2INSTANCE} << EOF
# db2 "deactivate db ${DBNAME}"
# db2 "list db directory"
# db2 "drop db ${DBNAME}"
# db2 "list db directory"
# db2 "restore database ${DBNAME} from /database/backup taken at $(ls -1tr /database/backup | tail -1 | grep ${DBNAME}.0.${DB2INSTANCE}.*.001 | awk -F'.' '{print $5}') encrypt without rolling forward"
# db2 "list db directory"
# EOF

#透過的暗号サンプルDB作成
su - ${DB2INSTANCE} -c "db2sampl -name ${DBNAME} -encrypt -verbose" 