#!/bin/bash

. /usr/local/etc/appliance.include

last_running="invalid"
if test -e /etc/appliance/last_running_ecs; then
    last_running=$(cat /etc/appliance/last_running_ecs || echo "invalid")
fi

/usr/local/sbin/prepare-ecs.sh --build-only
new_running=$(cat /etc/appliance/last_build_ecs || echo "invalid")

if test "$last_running" != "devserver" -a "$last_running" = "$new_running"; then
    echo "Warning: old version ($last_running) equal to new version ($new_running), will not restart"
else
    appliance_status "Appliance Update" "Restarting ecs"
    systemctl restart appliance
fi
