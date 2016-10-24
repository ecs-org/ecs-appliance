#!/bin/bash

APPLIANCE_GIT_BRANCH=${APPLIANCE_GIT_BRANCH:-master}

. /usr/local/etc/appliance.include
. /usr/local/etc/env.include

appliance_status "Appliance Update" "Updating appliance"

# fetch all updates from origin
gosu app git -C /app/appliance fetch -a -p

# set target to latest branch commit id
target=$(gosu app git -C /app/appliance rev-parse origin/$APPLIANCE_GIT_BRANCH)

# get current running commit id
last_running=$(gosu app git -C /app/appliance rev-parse HEAD)

appliance_status "Appliance Update" "Updating appliance from $last_running to $target"
salt-call state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'

appliance_status "Appliance Update" "Restarting appliance"
systemctl restart appliance
