#!/bin/bash

realpath=`dirname $(readlink -e "$0")`

if test -z "$2"; then
    cat << EOF
Usage: "$0 domain targetdir"

EOF
    exit 1
fi

sudo salt-call state.sls appliance.env_gen pillar="{\"domain\": \"$1\", \"targetdir\": \"$2\"}"
