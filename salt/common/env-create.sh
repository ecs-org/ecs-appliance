#!/bin/bash
realpath=$(dirname $(readlink -e "$0"))
template="salt://common/env-template.yml"
minion=""
fileroot=""
pillarroot=""
extra_env=""
appuser=$USER

if test "$1" = "--template"; then
    template=$(readlink -f "$2")
    shift 2
fi
if test "$1" = "--extra"; then
    extra_env=$(readlink -f "$2")
    shift 2
fi
if test -z "$2"; then
    cat << EOF
Usage: $0 [--template custom-template]
          [--extra additional-yaml-env]
          domain targetdir [optional salt-call parameter]
EOF
    exit 1
fi

domain=$1
targetdir=$(readlink -f "$2")
shift 2

if test -e $realpath/env-gen.sls; then
    echo "Info: we are called from the repository and not from a installed appliance"
    minion="--config-dir $(readlink -f $realpath/not-existing)"
    fileroot="--file-root $(readlink -f $realpath/../)"
    pillarroot="--pillar-root $(readlink -f $realpath/../../pillar)"
fi

sudo -- salt-call --local $fileroot $pillarroot $minion state.sls common.env-gen pillar="{ \
    \"domain\": \"$domain\", \
    \"template\": \"$template\", \
    \"extra_env\": \"$extra_env\", \
    \"targetdir\": \"$targetdir\", \
    \"appuser\": \"$appuser\" }" "$@"
