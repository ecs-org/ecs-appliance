#!/bin/sh
set -e
# customize hostname
config=/app/pdf-as-web/pdf-as-web.properties
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}

# copy server cert to system cert import location
cp /app/import/server.cert.pem /usr/local/share/ca-certificates/server.crt
chmod 0600 /usr/local/share/ca-certificates/server.crt

# copy letsencrypt ISRG Root X1 cert to system cert import location
cp /app/import/isrgrootx1.pem /usr/local/share/ca-certificates/isrgrootx1.pem

# update-ca-certificates also updates the java keystore
/usr/sbin/update-ca-certificates

exec /usr/local/tomcat/bin/catalina.sh "$@"
