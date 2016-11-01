#!/bin/sh
deploy_challenge() {
local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
}

clean_challenge() {
local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
}

unchanged_cert() {
local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
}

deploy_cert() {
local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
sudo /usr/local/sbin/newcert-as-root.sh $1 $2 $3 $4 $5 $6
}

HANDLER="$1"; shift
"$HANDLER" "$@"
