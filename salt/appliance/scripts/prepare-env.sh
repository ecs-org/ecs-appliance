#!/bin/bash
. /usr/local/share/appliance/env.include
# XXX appliance.include sets git_source* for appliance and ecs if empty env,
#  but this doesnt matter because we dont use it here
. /usr/local/share/appliance/appliance.include

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

# reset known metric flags
flag=/app/etc/flags/metric.collection
if is_truestr "$APPLIANCE_METRIC_COLLECTION"; then
    touch $flag
else
    if test -e $flag; then rm $flag; fi
fi

# check if standby is true
if is_truestr "$APPLIANCE_STANDBY"; then
    appliance_exit "Appliance Standby" "Appliance is in standby" "debug"
fi
