#!/bin/bash

APPLIANCE_GIT_BRANCH=${APPLIANCE_GIT_BRANCH:-master}

. /usr/local/etc/appliance.include
. /usr/local/etc/env.include

appliance_status "Appliance Update" "Updating appliance"
cd /app/appliance

# fetch all updates from origin
gosu app git fetch -a -p

# set target to latest branch commit id
target=$(gosu app git rev-parse origin/$APPLIANCE_GIT_BRANCH)

# get current running commit id
last_running=$(gosu app git rev-parse HEAD)

appliance_status "Appliance Update" "Updating appliance from $last_running to $target"

abort_ifnot_cleanrepo
ret=$?
if test $ret -eq 0; then
    git checkout -f $APPLIANCE_GIT_BRANCH
    git reset --hard origin/$APPLIANCE_GIT_BRANCH
else
    appliance_exit "Appliance Update" "Error, /app/appliance not clean, can not update"
fi

salt-call state.highstate pillar='{"appliance": {"enabled": true}}'

appliance_status "Appliance Update" "Restarting appliance"
systemctl restart appliance
