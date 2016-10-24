#!/bin/bash

APPLIANCE_GIT_BRANCH=$(APPLIANCE_GIT_BRANCH:-master)

. /usr/local/etc/appliance.include
. /usr/local/etc/env.include

appliance_status "Appliance Update" "updating appliance"

# fetch all updates from origin
gosu app git fetch -a -p -C /app/appliance

# set target to latest branch commit id
target=$(gosu app git rev-parse origin/$APPLIANCE_GIT_BRANCH -C /app/appliance)

# get current running commit id
last_running=$(gosu app git rev-parse HEAD -C /app/appliance)

appliance_status "Appliance Update" "updating appliance from $last_running to $target"
sudo salt-call state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'

appliance_status "Appliance Update" "starting appliance"
sudo systemctl restart appliance 
