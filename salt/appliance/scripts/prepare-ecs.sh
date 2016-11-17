#!/bin/bash

. /usr/local/etc/appliance.include
. /usr/local/etc/env.include

if test "$1" = "--build-only"; then build_only=true; shift; else build_only=false; fi

ecs_status()
{
    if $build_only; then
        echo "INFO: muted appliance status: $1 : $2"
    else
        appliance_status "$1" "$2"
    fi
}
ecs_exit()
{
    if $build_only; then
        echo "INFO: muted appliance status: $1 : $2"
        exit 1
    else
        appliance_exit "$1" "$2"
    fi
}

target="invalid"
ECS_GIT_BRANCH="${ECS_GIT_BRANCH:-deployment_fixes}"
ECS_GIT_SOURCE="${ECS_GIT_SOURCE:-ssh://git@gogs.omoikane.ep3.at:10022/ecs/ecs.git}"
ECS_DATABASE=ecs

if $build_only; then
    ecs_status "Appliance Update" "Starting ecs update build"
    printf "%s" "invalid" > /etc/appliance/last_build_ecs
fi

# export active yaml into environment
if test ! -e /app/active-env.yml; then
    ecs_exit "Appliance Error" "No /app/active-env.yml, did you run prepare_appliance ?"
fi
ENV_YML=/app/active-env.yml update_env_from_userdata ecs,appliance
if test $? -ne 0; then
    ecs_exit "Appliance Error" "Could not activate userdata environment"
fi

# check if standby is true
if is_truestr "$APPLIANCE_STANDBY"; then
    ecs_exit "Appliance Error" "Appliance is in standby, update aborted"
fi

# get target commit hash
if test -e /app/bin/devupdate.sh; then
    target="devserver"
elif test "$ECS_GIT_COMMITID" != ""; then
    target="$ECS_GIT_COMMITID"
fi

# clone source if currently not existing
if test ! -e /app/ecs/ecs/settings.py; then
    gosu app git clone --branch $ECS_GIT_BRANCH $ECS_GIT_SOURCE /app/ecs
fi


# update source, eval need_migration, last_running, target
cd /app/ecs

# fetch all updates from origin, except if devserver
if test "$target" != "devserver"; then
    gosu app git fetch -a -p
fi

# if target still invalid, set target to latest branch commit
if test "$target" = "invalid"; then
    target=$(gosu app git rev-parse origin/$ECS_GIT_BRANCH)
fi

# get last_running commit hash
if test -e /etc/appliance/last_running_ecs; then
    last_running=$(cat /etc/appliance/last_running_ecs || echo "invalid")
else
    last_running="invalid"
fi

need_migration=false
if test $target != "devserver"; then
    if test "$last_running" = "invalid"; then
        need_migration=true
    else
        need_migration=$(gosu app git diff --name-status $last_running..$target |
            grep -q "^A.*/migrations/" && echo true || echo false)
    fi
    # hard update source
    gosu app git checkout -f $ECS_GIT_BRANCH
    gosu app git reset --hard $target
fi


# rebuild images
cd /etc/appliance/ecs

ecs_status "Appliance Update" "Pulling base images"
for n in redis:3 memcached tomcat:8 ubuntu:xenial; do
    docker pull $n
done
if test -e /etc/appliance/rebuild_wanted_ecs -o "$last_running" = "devserver" -o "$target" != "$last_running"; then
    if test -e /etc/appliance/rebuild_wanted_ecs; then rm /etc/appliance/rebuild_wanted_ecs; fi
    ecs_status "Appliance Update" "Building ecs $target (current= $last_running)"
    if ! docker-compose build mocca pdfas ecs.web; then
        if "$last_running" = "invalid"; then
            ecs_exit "Appliance Error" "build $target failed and no old build found, standby"
        fi
        ecs_status "Appliance Error" "build $target failed, restarting old build $last_running"
        exit 0
    fi
    appliance_status "Appliance Update" "Build complete, starting ecs"
else
    ecs_status "Appliance Update" "Last version = current version = $last_running, skipping build"
    exit 0
fi
if $build_only; then
    printf "%s" "$target" > /etc/appliance/last_build_ecs
    exit 0
fi

if $need_migration; then
    docker-compose stop
    appliance_status "Appliance Update" "Pgdump ${ECS_DATABASE} database"
    dbdump=/data/ecs-pgdump/${ECS_DATABASE}-migrate.pgdump
    if gosu app pg_dump --encoding="utf-8" --format=custom -Z6 -f ${dbdump}.new -d $ECS_DATABASE; then
        mv ${dbdump}.new ${dbdump}
    else
        appliance_exit "Appliance Error" "Could not pgdump database $ECS_DATABASE before starting migration"
    fi
    appliance_status "Appliance Update" "Migrating ecs database"
    docker-compose run --no-deps --rm --name ecs.migration ecs.web migrate
    err=$?
    if test $err -ne 0; then
        appliance_exit "Appliance Error" "Migration Error"
    fi
fi

# save next about to be executed commit
printf "%s" "$target" > /etc/appliance/last_running_ecs
