#!/bin/sh
local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
ln -sf /etc/appliance/server.key.pem $KEYFILE
ln -sf /etc/appliance/server.cert.pem $FULLCHAINFILE
printf "%s" "$(if test -e /etc/appliance/dhparam.pem; then cat /etc/appliance/dhparam.pem; fi)" | cat /etc/appliance/server.cert.pem - > /etc/appliance/server.cert.dhparam.pem
