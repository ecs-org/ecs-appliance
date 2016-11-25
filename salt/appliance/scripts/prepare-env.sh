#!/bin/bash
. /usr/local/etc/env.include
. /usr/local/etc/appliance.include

# ### environment setup, read userdata
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    appliance_exit "Appliance Error" "$(printf "Error reading userdata: %s" `echo "$userdata_yaml"| grep USERDATA_ERR`)"
fi
echo -n "found user-data type: "
printf '%s' "$userdata_yaml" | grep USERDATA_TYPE
echo "write userdata to /run/active-env.yml"
printf "%s" "$userdata_yaml" > /run/active-env.yml
chmod 0600 /run/active-env.yml

# test: export active yaml into environment
ENV_YML=/run/active-env.yml userdata_to_env ecs,appliance
if test $? -ne 0; then
    appliance_exit "Appliance Error" "Could not activate userdata environment"
fi

# check if standby is true
if is_truestr "$APPLIANCE_STANDBY"; then
    appliance_exit_standby
fi
