#!/bin/sh
set -e
# customize hostname
config=/app/mocca/bkuonline-configuration.xml
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}

# add certs to unpacked bkuonline, needed in addition to standard-keystore
certs_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs"
tobeadded_dir="$certs_dir/certStore/toBeAdded"
truststore_dir="$certs_dir/trustStore"
mkdir -p $tobeadded_dir $truststore_dir
cp /app/import/server.cert.pem $tobeadded_dir
cp /app/import/server.cert.pem $truststore_dir

# copy cert to import location, update-ca-certificates also updates the java keystore
cp /app/import/server.cert.pem /usr/local/share/ca-certificates/server.crt
chmod 0600 /usr/local/share/ca-certificates/server.crt
/usr/sbin/update-ca-certificates

exec /usr/local/tomcat/bin/catalina.sh "$@"
