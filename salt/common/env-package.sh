#!/bin/bash
if test -z "$1"; then
    cat << EOF
Usage: $0 path/to/env.yml   # builds environment package
       $0 --requirements    # installs needed package for package building
EOF
    exit 1
fi

realpath=$(dirname $(readlink -e "$0"))
minion=""
fileroot=""
pillarroot=""
envinclude=/usr/local/share/appliance/env.include
qrpdf2data=$(which qrpdf2data.sh)

if test -e $realpath/env-package-req.sls; then
    echo "Info: we are called from the repository and not from a installed appliance"
    minion="--config-dir $(readlink -f $realpath/not-existing)"
    fileroot="--file-root $(readlink -f $realpath/../)"
    pillarroot="--pillar-root $(readlink -f $realpath/../../pillar)"
    envinclude=$realpath/env.include
    qrpdf2data=$realpath/../qrcode/qrpdf2data.sh
fi

if test "$1" = "--requirements"; then
    echo "sudo -- salt-call --local $fileroot $pillarroot $minion state.sls common.env-package-req"
    sudo -- salt-call --local $fileroot $pillarroot $minion state.sls common.env-package-req
    exit $?
elif test ! -e "$1"; then
    echo "error: environment yaml file $1 not found."
    exit 1
fi

. $envinclude
sourcefile=$(readlink -f "$1")
targetdir=$(dirname $sourcefile)
ENV_YML=$sourcefile userdata_to_env ecs,appliance
outputname="${APPLIANCE_DOMAIN}.env.$(date +%Y-%m-%d_%H.%M).tar.gz.gpg"

cd $targetdir
cp $qrpdf2data qrpdf2data.sh
cat > meta-data << EOF
instance-id: iid-cloud-default
local-hostname: $APPLIANCE_DOMAIN
EOF
cat $sourcefile | gzip -9 > env.yml.gz
data2qrpdf.sh env.yml.gz
enscript -p - env.yml | ps2pdf - env.yml.txt.pdf
enscript -p - qrpdf2data.sh | ps2pdf - qrpdf2data.sh.pdf
pdftk env.yml.txt.pdf env.yml.gz.pdf qrpdf2data.sh.pdf cat output env.yml.pdf
shred -u env.yml.gz env.yml.gz.pdf env.yml.txt.pdf qrpdf2data.sh.pdf qrpdf2data.sh
genisoimage -volid cidata -joliet -rock -input-charset utf-8 \
    -output env-cidata.iso -graft-points user-data=env.yml meta-data env.yml.pdf
rm meta-data

if test "$APPLIANCE_ENV_PACKAGE_KEYS_LEN" != ""; then
    gpghome="./.envpkggnupg"
    gpgopts="--homedir $gpghome --batch --yes"
    if test -d $gpghome; then rm -r $gpghome; fi
    mkdir $gpghome

    for i in $(seq 0 $(( $APPLIANCE_ENV_PACKAGE_KEYS_LEN -1 )) ); do
        fieldname="APPLIANCE_ENV_PACKAGE_KEYS_${i}"; data="${!fieldname}"
        echo "$data" | gpg $gpgopts --import --
    done

    keylist=$(gpg $gpgopts --keyid-format 0xLONG --list-keys | grep "pub .*/0x" | sed -r "s/pub.+0x([0-9A-F]+).+/\1/g")

    tar cz env.yml env.yml.pdf env-cidata.iso | \
        LANG=c gpg $gpgopts --trust-model always --encrypt \
            $(for r in $keylist; do printf " --recipient %s " "$r"; done) \
        > $outputname

    rm -r ./.envpkggnupg

    if test "$2" = "--send-email"; then
        swaks whatever
    fi
fi
