#!/bin/bash

. /usr/local/etc/appliance.include

is_cleanrepo(){
    local repo="${1:-.}"
    if ! gosu app git -C $repo diff-files --quiet --ignore-submodules --; then
        echo "Error: abort, your working directory is not clean."
        gosu app git -C $repo --no-pager diff-files --name-status -r --ignore-submodules --
        return 1
    fi
    if ! gosu app git -C $repo diff-index --cached --quiet HEAD --ignore-submodules --; then
        echo "Error: abort, you have cached and or staged changes"
        gosu app git -C $repo --no-pager diff-index --cached --name-status -r --ignore-submodules HEAD --
        return 1
    fi
    if test "$(gosu app git -C $repo ls-files --other --exclude-standard --directory)" != ""; then
        echo "Error: abort, working directory has extra files"
        gosu app git -C $repo --no-pager ls-files --other --exclude-standard --directory
        return 1
    fi
    if test "$(gosu app git -C $repo log --branches --not --remotes --pretty=format:'%H')" != ""; then
        echo "Error: abort, there are unpushed changes"
        gosu app git -C $repo --no-pager log --branches --not --remotes --pretty=oneline
        return 1
    fi
    return 0
}

if test ! -e /app/appliance; then gosu app mkdir -p /app/appliance; fi
cd /app/appliance
if ! is_cleanrepo; then
    echo "Error: Appliance directory not clean, can not update /app/appliance"
    exit 1
fi
appliance_status "Appliance Update" "Updating appliance"
# if APPLIANCE_GIT_SOURCE is different to current remote repository,
#   or if current source dir is empty: delete source, re-clone
current_source=$(gosu app git config --get remote.origin.url || echo "")
if test "$APPLIANCE_GIT_SOURCE" != "$current_source"; then
    sentry_entry "Appliance Update" "Warning: appliance has different upstream sources, will re-clone. Current: \"$current_source\", new: \"$APPLIANCE_GIT_SOURCE\""
    cd /; rm -r /app/appliance; gosu app mkdir -p /app/appliance; cd /app/appliance
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
