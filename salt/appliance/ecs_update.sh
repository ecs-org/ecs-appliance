#!/bin/bash

. /usr/local/etc/appliance.include

/usr/local/sbin/prepare_ecs.sh --update

appliance_status "Appliance Update" "restarting ecs"
sudo systemctl restart appliance
