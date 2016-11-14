#!/bin/bash

. /usr/local/etc/appliance.include

is_cleanrepo(){
    local repo="${1:-.}"
    if ! git -C $repo diff-files --quiet --ignore-submodules --; then
        echo "Error: abort, your working directory is not clean."
        git  -C $repo --no-pager diff-files --name-status -r --ignore-submodules --
        return 1
    fi
    if ! git -C $repo diff-index --cached --quiet HEAD --ignore-submodules --; then
        echo "Error: abort, you have cached and or staged changes"
        git -C $repo --no-pager diff-index --cached --name-status -r --ignore-submodules HEAD --
        return 1
    fi
    if test "$(git -C $repo ls-files --other --exclude-standard --directory)" != ""; then
        echo "Error: abort, working directory has extra files"
        git -C $repo --no-pager ls-files --other --exclude-standard --directory
        return 1
    fi
    if test "$(git -C $repo log --branches --not --remotes --pretty=format:'%H')" != ""; then
        echo "Error: abort, there are unpushed changes"
        git -C $repo --no-pager log --branches --not --remotes --pretty=oneline
        return 1
    fi
    return 0
}

APPLIANCE_GIT_BRANCH=${APPLIANCE_GIT_BRANCH:-master}

appliance_status "Appliance Update" "Updating appliance"
cd /app/appliance

# fetch all updates from origin
gosu app git fetch -a -p

# set target to latest branch commit id
target=$(gosu app git rev-parse origin/$APPLIANCE_GIT_BRANCH)

# get current running commit id
last_running=$(gosu app git rev-parse HEAD)
appliance_status "Appliance Update" "Updating appliance from $last_running to $target"

if is_cleanrepo; then
    gosu app git checkout -f $APPLIANCE_GIT_BRANCH
    gosu app git reset --hard origin/$APPLIANCE_GIT_BRANCH
else
    appliance_exit "Appliance Error" "Error: appliance directory not clean, can not update"
fi

salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
# save executed commit
printf "%s" "$target" > /etc/appliance/last_running_appliance

appliance_status "Appliance Update" "Restarting appliance"
systemctl restart appliance
