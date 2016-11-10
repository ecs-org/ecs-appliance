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

sudo salt-call state.sls common.env_gen \
    pillar="{\"domain\": \"$domain\", \"targetdir\": \"$targetdir\", \"appuser\": \"$appuser\"}" $@

exit 0

> $targetdir/meta-data << EOF
instance-id: iid-cloud-default
local-hostname: linux
EOF

genisoimage -volid cidata -joliet -rock -input-charset utf-8 -output $targetdir/ecs-env-cidata.iso -graft-points user-data=$targetdir/env.yml meta-data=$targetdir/meta-data

data2qrpdf env.yml
