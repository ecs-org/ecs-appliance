#!/bin/sh

set -e
config=/app/pdf-as-web/pdf-as-web.properties
sed "s/HOSTNAME/$HOSTNAME/g" ${config}.tmpl > ${config}
exec /usr/local/tomcat/bin/catalina.sh "$@"
