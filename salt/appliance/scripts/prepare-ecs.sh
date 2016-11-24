#!/bin/bash

. /usr/local/etc/appliance.include

build_only=false
if test "$1" = "--build-only"; then build_only=true; shift; fi

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


# ### update source
last_running=$((cat /etc/appliance/last_running_ecs || echo "invalid") 2> /dev/null)
need_migration=false
target="invalid"
if test ! -e /app/ecs; then gosu app mkdir -p /app/ecs; fi
cd /app/ecs

if test -e /app/bin/devupdate.sh; then
    target="devserver"
else
    if test "$ECS_GIT_COMMITID" != ""; then
        target="$ECS_GIT_COMMITID"
    fi
    # if ECS_GIT_SOURCE is different to current remote repository,
    #   or if current source dir is empty: delete source
    current_source=$(gosu app git config --get remote.origin.url || echo "")
    if test "$ECS_GIT_SOURCE" != "$current_source"; then
        sentry_entry "Appliance Update" "Warning: ecs has different upstream sources, will re-clone. Current: \"$current_source\", new: \"$ECS_GIT_SOURCE\""
        cd /; rm -r /app/ecs; gosu app mkdir -p /app/ecs; cd /app/ecs
    fi
    # clone source if currently not existing
    if test ! -e /app/ecs/ecs/settings.py; then
        gosu app git clone --branch $ECS_GIT_BRANCH $ECS_GIT_SOURCE /app/ecs
    fi
    # fetch all updates from origin
    gosu app git fetch -a -p
    # if target still invalid, set target to latest branch commit
    if test "$target" = "invalid"; then
        target=$(gosu app git rev-parse origin/$ECS_GIT_BRANCH)
    fi
    # check if migration is needed
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


# ### rebuild images
cd /etc/appliance/ecs
printf "%s" "invalid" > /etc/appliance/last_build_ecs

ecs_status "Appliance Update" "Pulling base images"
for n in redis:3 memcached tomcat:8-jre8 ubuntu:xenial; do
    docker pull $n
done

if test -e /etc/appliance/rebuild_wanted_ecs -o \
    "$last_running" = "devserver" -o \
    "$target" != "$last_running"; then

    if test -e /etc/appliance/rebuild_wanted_ecs; then
        rm /etc/appliance/rebuild_wanted_ecs
    fi
    ecs_status "Appliance Update" "Building ECS $target (current= $last_running)"
    if ! docker-compose build mocca pdfas ecs.web; then
        sentry_entry "Appliance Update" "ECS build failed" error
        if "$last_running" = "invalid"; then
            ecs_exit "Appliance Error" "ECS build $target failed and no old build found, standby"
        fi
        ecs_status "Appliance Update" "ECS build failed, restarting old image"
        exit 0
    fi
    appliance_status "Appliance Update" "ECS build complete, starting ecs"
else
    ecs_status "Appliance Update" "ECS Last version = current version = $last_running, skipping build"
    exit 0
fi
printf "%s" "$target" > /etc/appliance/last_build_ecs
if $build_only; then
    exit 0
fi
# save next about to be executed commit
printf "%s" "$target" > /etc/appliance/last_running_ecs


# ### migrate database
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
    (docker images -q ecs/ecs:latest || echo "invalid") > /etc/appliance/last_running_ecs_image
    docker-compose run --no-deps --rm --name ecs.migration ecs.web migrate
    err=$?
    if test $err -ne 0; then
        appliance_exit "Appliance Error" "Migration Error"
    fi
fi
