#!/bin/bash

realpath=`dirname $(readlink -e "$0")`

if test -z "$2"; then
    cat << EOF
Usage: "$0 domain targetdir"

EOF
    exit 1
fi

targetdir=$(readlink -e "$2")

sudo salt-call state.sls common.env_gen pillar="{\"domain\": \"$1\", \"targetdir\": \"$targetdir\"}"
