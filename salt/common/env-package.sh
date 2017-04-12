#!/bin/bash
if test -z "$1"; then
    cat << EOF
Usage: $0 path/to/env.yml   # builds environment package
       $0 --requirements    # installs needed package for package building

Options:
    The following files may exist in the same directory as env.yml:
    "meta-data.custom": custom meta-data for the seed iso, eg. static IP
    "gpgkeys.txt": gpg ascii armored keys concatted together, used as the gpg encryption target
    "emailto.txt": will send encrypted config to every email address listed, one per line
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
outputtime="$(date +%Y-%m-%d_%H.%M)"
outputname="${APPLIANCE_DOMAIN}.env.$outputtime.tar.gz.gpg"


cd $targetdir
cp $qrpdf2data qrpdf2data.sh
if test -e $targetdir/meta-data.custom; then
    cp $targetdir/meta-data.custom $targetdir/meta-data
else
    cat > meta-data << EOF
instance-id: iid-cloud-default
local-hostname: $APPLIANCE_DOMAIN
EOF
fi

cat $sourcefile | gzip -9 > env.yml.gz
data2qrpdf.sh env.yml.gz
enscript -p - env.yml | ps2pdf - env.yml.txt.pdf
enscript -p - qrpdf2data.sh | ps2pdf - qrpdf2data.sh.pdf
pdftk env.yml.txt.pdf env.yml.gz.pdf qrpdf2data.sh.pdf cat output env.yml.pdf
shred -u env.yml.gz env.yml.gz.pdf env.yml.txt.pdf qrpdf2data.sh.pdf qrpdf2data.sh
genisoimage -volid cidata -joliet -rock -input-charset utf-8 \
    -output env-cidata.iso -graft-points user-data=env.yml meta-data env.yml.pdf
rm meta-data

if test -e $targetdir/gpgkeys.txt; then
    gpghome="./.envpkggnupg"
    gpgopts="--homedir $gpghome --batch --yes"
    if test -d $gpghome; then rm -r $gpghome; fi
    mkdir $gpghome

    cat $targetdir/gpgkeys.txt | gpg $gpgopts --import --
    keylist=$(gpg $gpgopts --keyid-format 0xLONG --list-keys | grep "pub .*/0x" | sed -r "s/pub.+0x([0-9A-F]+).+/\1/g")

    echo "Package and encrypt config to $outputname"
    tar cz env.yml env.yml.pdf env-cidata.iso | \
        LANG=c gpg $gpgopts --trust-model always --encrypt \
            $(for r in $keylist; do printf " --recipient %s " "$r"; done) \
        > $outputname

    rm -r ./.envpkggnupg

    if test -e $targetdir/emailto.txt; then
        to=$(cat $targetdir/emailto.txt | grep -v '^$' | paste -s -d"," -)
        body="This email was sent to $to.

Attached is the encrypted config file $outputname
of the ecs appliance for the domain: $APPLIANCE_DOMAIN

It was last modified on: $outputtime.

"
        echo "Sending email to $to"
        echo "$body" | swaks --to $to --attach $outputname --body -
    fi
fi
