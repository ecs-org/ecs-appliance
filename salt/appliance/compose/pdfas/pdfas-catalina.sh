#!/bin/sh
set -e
# customize hostname
config=/app/pdf-as-web/pdf-as-web.properties
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}

# copy cert to import location, update-ca-certificates also updates the java keystore
cp /app/import/server.cert.pem /usr/local/share/ca-certificates/server.crt
chmod 0600 /usr/local/share/ca-certificates/server.crt
/usr/sbin/update-ca-certificates

exec /usr/local/tomcat/bin/catalina.sh "$@"
