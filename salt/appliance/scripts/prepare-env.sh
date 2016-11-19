#!/bin/bash

. /usr/local/etc/env.include
. /usr/local/etc/appliance.include

# ### environment setup
# read userdata
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    appliance_exit "Appliance Error" "$(printf "Error reading userdata: %s" `echo "$userdata_yaml"| grep USERDATA_ERR`)"
fi
echo -n "found user-data type: "
printf '%s' "$userdata_yaml" | grep USERDATA_TYPE
echo "write userdata to /app/active-env.yml"
printf "%s" "$userdata_yaml" > /app/active-env.yml
chmod 0600 /app/active-env.yml
echo "write systemd EnvironmentFile to /app/active-env.env"
ENV_YML=/app/active-env.yml userdata_to_envlist ecs,appliance --alt-multiline > /app/active-env.env
chmod 0600 /app/active-env.env

# test: export active yaml into environment
ENV_YML=/app/active-env.yml update_env_from_userdata ecs,appliance
if test $? -ne 0; then
    appliance_exit "Appliance Error" "Could not activate userdata environment"
fi

# check if standby is true
if is_truestr "$APPLIANCE_STANDBY"; then
    appliance_exit_standby
fi
