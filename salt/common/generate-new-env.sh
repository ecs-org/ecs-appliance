#!/bin/bash

realpath=`dirname $(readlink -e "$0")`

if test -z "$2"; then
    cat << EOF
Usage: "$0 domain targetdir [optional parameter for salt-call]"

todo: --developer-default add a user friendly way to get the default-env.yml


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


cd $targetdir

> meta-data << EOF
instance-id: iid-cloud-default
local-hostname: linux
EOF

cat env.yml | gzip -9 > env.yml.gz
data2qrpdf env.yml.gz
enscript -p - env.yml | ps2pdf - env.yml.txt.pdf
enscript -p - $(which qrpdf2data.sh) | ps2pdf - qrpdf2data.sh.pdf
pdftk env.yml.txt.pdf env.yml.gz.pdf qrpdf2data.sh.pdf cat output env.yml.pdf
shred -u env.yml.gz env.yml.gz.pdf env.yml.txt.pdf qrpdf2data.sh.pdf
genisoimage -volid cidata -joliet -rock -input-charset utf-8 -output env-cidata.iso -graft-points user-data=env.yml meta-data env.yml.pdf
rm meta-data
tar cz env.yml env.yml.pdf | gpg --encrypt > "${domain}.ecs.env.$(datetime).tar.gz.gpg"
