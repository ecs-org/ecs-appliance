#!/bin/bash

. /usr/local/etc/appliance.include

# get last_running commit hash
last_running="invalid"
if test -e /etc/appliance/last_running_ecs; then
    last_running=$(cat /etc/appliance/last_running_ecs || echo "invalid")
fi

/usr/local/sbin/prepare-ecs.sh --update

new_running=$(cat /etc/appliance/last_running_ecs || echo "invalid")

if test "$last_running" = "$new_running"; then
    echo "Warning: old version ($last_running) equal to new version ($new_running), will not restart"
else
    appliance_status "Appliance Update" "Restarting ecs"
    systemctl restart appliance
fi
