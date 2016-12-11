#!/bin/bash
. /usr/local/share/appliance/env.include
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    printf "Error reading userdata: %s\n" $(echo "$userdata_yaml"| grep USERDATA_ERR)
fi
printf "found user-data: %s\n" "$(printf "%s" "$userdata_yaml" | grep USERDATA_TYPE)"
printf "write userdata to /run/active-env.yml\n"
printf "%s" "$userdata_yaml" > /run/active-env.yml
chmod 0600 /run/active-env.yml
