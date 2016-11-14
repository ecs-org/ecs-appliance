#!/bin/sh

set -e
config=/app/mocca/bkuonline-configuration.xml
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}

tobeadded_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs/certStore/toBeAdded"
truststore_dir="/usr/local/tomcat/webapps/bkuonline/WEB-INF/classes/at/gv/egiz/bku/certs/trustStore"

mkdir -p $tobeadded_dir
mkdir -p $truststore_dir
cp /data/server.cert.pem $tobeadded_dir
cp /data/server.cert.pem $truststore_dir

exec /usr/local/tomcat/bin/catalina.sh "$@"
