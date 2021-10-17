#!/bin/sh
set -e
# customize hostname
config=/app/mocca/bkuonline-configuration.xml
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}

# add host certs to unpacked bkuonline, needed in addition to standard-keystore
certs_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs"
tobeadded_dir="$certs_dir/certStore/toBeAdded"
truststore_dir="$certs_dir/trustStore"

mkdir -p $tobeadded_dir $truststore_dir
cp /app/import/server.cert.pem $tobeadded_dir
cp /app/import/server.cert.pem $truststore_dir

# copy letsencrypt ISRG Root X1 cert to system cert import location
cp /app/import/isrgrootx1.pem $tobeadded_dir
cp /app/import/isrgrootx1.pem $truststore_dir

# copy server cert to system cert import location
cp /app/import/server.cert.pem /usr/local/share/ca-certificates/server.crt
chmod 0600 /usr/local/share/ca-certificates/server.crt

# copy letsencrypt ISRG Root X1 cert to system cert import location
cp /app/import/isrgrootx1.pem /usr/local/share/ca-certificates/isrgrootx1.pem

# update-ca-certificates also updates the java keystore
/usr/sbin/update-ca-certificates

exec /usr/local/tomcat/bin/catalina.sh "$@"
