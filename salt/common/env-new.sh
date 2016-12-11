#!/bin/bash

realpath=`dirname $(readlink -e "$0")`

if test -z "$2"; then
    cat << EOF
Usage: "$0 domain targetdir [optional parameter for salt-call]"

EOF
    exit 1
fi

domain=$1
targetdir=$(readlink -f "$2")
shift 2
appuser=$USER

sudo salt-call state.sls common.env-gen \
    pillar="{\"domain\": \"$domain\", \
    \"template\": \"salt://common/env-template.yml\", \
    \"targetdir\": \"$targetdir\", \"appuser\": \"$appuser\"}" "$@"

exit 0
