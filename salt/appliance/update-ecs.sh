#!/bin/bash

. /usr/local/etc/appliance.include

/usr/local/sbin/prepare-ecs.sh --update

appliance_status "Appliance Update" "Restarting ecs"
systemctl restart appliance
