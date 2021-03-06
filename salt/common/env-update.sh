#!/bin/bash
realpath=$(dirname $(readlink -e "$0"))
if test -e $realpath/env.include; then
    # we are called from the repository and not from a installed appliance, correct paths
    . $realpath/env.include
else
    . /usr/local/share/appliance/env.include
fi

userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    printf "Error reading userdata: %s\n" $(echo "$userdata_yaml"| grep USERDATA_ERR)
    exit 1
fi

printf "found user-data: %s\n" "$(printf "%s" "$userdata_yaml" | grep USERDATA_TYPE)"
printf "write userdata to /run/active-env.yml\n"
printf "%s" "$userdata_yaml" > /run/active-env.yml
chmod 0600 /run/active-env.yml
