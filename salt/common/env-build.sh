#!/bin/bash
if test -z "$1"; then
    cat << EOF
Usage: "$0 path/to/env.yml"
EOF
    exit 1
fi

. /usr/local/share/appliance/env.include
realpath=$(dirname $(readlink -e "$0"))
targetfile=$(basename $(readlink -f "$1"))
targetdir=$(dirname $(readlink -f "$1"))
ENV_YML=$targetfile userdata_to_env ecs,appliance

cd $targetdir
> meta-data << EOF
instance-id: iid-cloud-default
local-hostname: $APPLIANCE_DOMAIN
EOF
cat $targetfile | gzip -9 > env.yml.gz
data2qrpdf env.yml.gz
enscript -p - env.yml | ps2pdf - env.yml.txt.pdf
enscript -p - $(which qrpdf2data.sh) | ps2pdf - qrpdf2data.sh.pdf
pdftk env.yml.txt.pdf env.yml.gz.pdf qrpdf2data.sh.pdf cat output env.yml.pdf
shred -u env.yml.gz env.yml.gz.pdf env.yml.txt.pdf qrpdf2data.sh.pdf
genisoimage -volid cidata -joliet -rock -input-charset utf-8 -output env-cidata.iso -graft-points user-data=env.yml meta-data env.yml.pdf
rm meta-data
tar cz env.yml env.yml.pdf env-cidata.iso | \
    gpg --encrypt > "${APPLIANCE_DOMAIN}.env.$(date +%Y-%m-%d_%H.%M).tar.gz.gpg"
