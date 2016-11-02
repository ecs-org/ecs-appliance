#!/bin/sh
local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
/usr/local/sbin/unchanged_cert_as_root.sh $1 $2 $3 $4 $5
systemctl reload-or-restart nginx
systemctl restart stunnel
systemctl restart postfix
