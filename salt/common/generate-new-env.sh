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
sudo mkdir -p $targetdir
sudo salt-call state.sls common.env_gen pillar="{\"domain\": \"$domain\", \"targetdir\": \"$targetdir\"}" $@
sudo chown $USER:$USER $targetdir/env.yml
