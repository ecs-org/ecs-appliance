#!/bin/bash
. /usr/local/share/appliance/env.include
# XXX appliance.include sets git_source* for appliance and ecs if empty env,
#  but this doesnt matter because we dont use it here
. /usr/local/share/appliance/appliance.include

flag_and_service_enable () {
    touch /app/etc/flags/$1
    systemctl start $2
}

flag_and_service_disable () {
    if test -e /app/etc/flags/$1; then rm /app/etc/flags/$1; fi
    systemctl stop $2
}

# ### environment setup, read userdata
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    appliance_exit "Appliance Error" "$(printf "Error reading userdata: %s" `echo "$userdata_yaml"| grep USERDATA_ERR`)"
fi
printf "found user-data: %s\n" "$(printf "%s" "$userdata_yaml" | grep USERDATA_TYPE)"
printf "write userdata to /run/active-env.yml\n"
printf "%s" "$userdata_yaml" > /run/active-env.yml
chmod 0600 /run/active-env.yml

# test: export active yaml into environment
ENV_YML=/run/active-env.yml userdata_to_env ecs,appliance
if test $? -ne 0; then
    appliance_exit "Appliance Error" "Could not activate userdata environment"
fi

# check if standby is true
if is_truestr "$APPLIANCE_STANDBY"; then
    appliance_exit "Appliance Standby" "Appliance is in standby" "debug"
fi

# set/clear flags and start/stop services connected to flags
services="cadvisor.service node-exporter.service postgres_exporter.service process-exporter.service"
if is_truestr "$APPLIANCE_METRIC_COLLECTION"; then
    flag_and_service_enable "metric.collection" "$services"
else
    flag_and_service_disable "metric.collection" "$services"
fi
services="prometheus.service alertmanager.service"
if is_truestr "$APPLIANCE_METRIC_SERVER"; then
    flag_and_service_enable "metric.server" "$services"
else
    flag_and_service_disable "metric.server" "$services"
fi
if is_truestr "$APPLIANCE_METRIC_GUI"; then
    flag_and_service_enable "metric.gui" "grafana.service"
else
    flag_and_service_disable "metric.gui" "grafana.service"
fi
if is_truestr "$APPLIANCE_METRIC_PGHERO"; then
    flag_and_service_enable "metric.pghero" "pghero-container.service"
else
    flag_and_service_disable "metric.pghero" "pghero-container.service"
fi
