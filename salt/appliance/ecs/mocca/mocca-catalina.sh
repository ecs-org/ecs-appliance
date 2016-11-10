#!/bin/sh

mocca_config=/app/mocca-configuration.xml
sed "s/HOSTNAME/$HOSTNAME/g" ${mocca_config}.tmpl > ${mocca_config}
printf "%s" "$SERVER_CERT" > /app/server.cert.pem
tobeadded_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs/certStore/toBeAdded"
truststore_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs/trustStore
"

mkdir -p $tobeadded_dir
mkdir -p $truststore_dir
cp /app/server.cert.pem $tobeadded_dir
cp /app/server.cert.pem $truststore_dir

exec /usr/local/bin/catalina.sh "$@"
