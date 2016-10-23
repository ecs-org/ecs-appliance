#!/bin/bash

target="invalid"
ECS_GIT_BRANCH=$(ECS_GIT_BRANCH:-master)
ECS_GIT_SOURCE=$(ECS_GIT_SOURCE:-https://github.com/ethikkom/ecs.git)
ECS_DATABASE=ecs

. /usr/local/etc/appliance.include
. /usr/local/etc/env.include

nginx_redirect_to_status "Appliance Startup" "starting up ecs"

# export active yaml into environment
if test ! -e /app/active-env.yml; then
    nginx_redirect_to_status "Appliance Error" "no /app/active-env.yml, did you run prepare_appliance ?"
    exit 1
fi
ENV_YML=/app/active-env.yml update_env_from_userdata

# check if standby is true
if test "$($APPLIANCE_STANDBY| tr A-Z a-z)" = "true"; then
    nginx_redirect_to_status "Appliance Standby" "Appliance is in standby, please contact sysadmin"
    exit 1
fi

#get target commit hash
if test -e /app/bin/devupdate.sh; then
    target="devserver"
elif test "$ECS_GIT_COMMITID" != ""; then
    target="$ECS_GIT_COMMITID"
fi

# clone source if currently not existing
if test ! -e /app/ecs/ecs/settings.py; then
    gosu app git clone --branch $ECS_GIT_BRANCH $ECS_GIT_SOURCE /app/ecs
fi

# fetch all updates from origin, except if devserver
if test "$target" != "devserver"; then
    gosu app git fetch -a -p -C /app/ecs
fi

# if target still invalid, set target to latest branch commit
if test "$target" = "invalid"; then
    target=$(gosu app git rev-parse origin/$ECS_GIT_BRANCH -C /app/ecs)
fi

# get last_running commit hash
if test -e /etc/appliance/ECS_COMMIT_ID; then
    last_running=$(cat /etc/appliance/ECS_GIT_COMMITID || echo "invalid")
else
    last_running="invalid"
fi

if test $target = "devserver"; then
    need_migration=false
else
    if test "$last_running" = "invalid"; then
        need_migration=true
    else
        need_migration=$(gosu app git diff --name-status $last_running..origin/$target -C /app/ecs |
            grep -q "^A.*/migrations/" && echo true || echo false)
    fi
fi

cd /etc/appliance/compose
docker-compose build --pull
docker-compose stop

if need_migration; then
    dbdump=/data/ecs-pgdump/$ECS_DATABASE.pgdump
    if gosu app pg_dump --encoding="utf-8" --format=custom -Z6 -f ${dbdump}.new -d $ECS_DATABASE; then
        mv ${dbdump}.new ${dbdump}
    else
        nginx_redirect_to_status "Appliance Error" "Could not pgdump database $ECS_DATABASE before starting migration"
        exit 1
    fi
    docker-compose run ecs.web --name ecs.migration --no-deps migrate
fi
