#!/bin/sh
set -e
# customize hostname
config=/app/mocca/bkuonline-configuration.xml
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}

# add certs to unpacked bkuonline, needed in addition to standard-keystore
tobeadded_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs/certStore/toBeAdded"
truststore_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs/trustStore"
mkdir -p $tobeadded_dir
mkdir -p $truststore_dir
cp /app/import/server.cert.pem $tobeadded_dir
cp /app/import/server.cert.pem $truststore_dir

# add cert to standard-keystore
# update-ca-certificates will also update the java keystore (if ca-certificates-java is installed)
cp /app/import/server.cert.pem /usr/local/share/ca-certificates/server.crt
chmod 0600 /usr/local/share/ca-certificates/server.crt
/usr/sbin/update-ca-certificates

exec /usr/local/tomcat/bin/catalina.sh "$@"
