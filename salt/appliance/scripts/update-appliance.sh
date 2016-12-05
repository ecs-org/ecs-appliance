#!/bin/bash
. /usr/local/etc/env.include
ENV_YML=/run/active-env.yml userdata_to_env ecs,appliance
if test $? -ne 0; then
    echo "Could not activate userdata environment"
    exit 1
fi
. /usr/local/etc/appliance.include

if test ! -e /app/appliance; then mkdir -p /app/appliance; chown app:app /app/appliance; fi
cd /app/appliance

appliance_status "Appliance Update" "Updating appliance"
# if APPLIANCE_GIT_SOURCE is different to current remote, delete source, re-clone
current_source=$(gosu app git config --get remote.origin.url || echo "")
if test "$APPLIANCE_GIT_SOURCE" != "$current_source"; then
    sentry_entry "Appliance Update" "Warning: appliance has different upstream sources, will re-clone. Current: \"$current_source\", new: \"$APPLIANCE_GIT_SOURCE\""
    cd /; rm -r /app/appliance; mkdir -p /app/appliance; chown app:app /app/appliance; cd /app/appliance
    gosu app git clone --branch $APPLIANCE_GIT_BRANCH $APPLIANCE_GIT_SOURCE /app/appliance
fi

# fetch all updates from origin
gosu app git fetch -a -p
# set target to latest branch commit id
target=$(gosu app git rev-parse origin/$APPLIANCE_GIT_BRANCH)
# get current running commit id
last_running=$(gosu app git rev-parse HEAD)
# hard update source
appliance_status "Appliance Update" "Updating appliance from $last_running to $target"
gosu app git checkout -f $APPLIANCE_GIT_BRANCH
gosu app git reset --hard origin/$APPLIANCE_GIT_BRANCH

if test "$last_running" != "$target"; then
    # appliance code has updated, we need a rebuild of ecs container
    touch /etc/appliance/rebuild_wanted_ecs
fi

salt-call state.highstate pillar='{"appliance": {"enabled": true}}' --retcode-passthrough --return appliance
err=$?
if test $err -ne 0; then
    appliance_exit "Appliance Error" "salt-call state.highstate failed with error $err"
fi

# save executed commit
printf "%s" "$target" > /etc/appliance/last_running_appliance
appliance_status "Appliance Update" "Restarting appliance"
systemctl restart appliance
