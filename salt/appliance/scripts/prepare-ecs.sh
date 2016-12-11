#!/bin/bash
. /usr/local/share/appliance/appliance.include

last_running=$(cat /app/etc/tags/last_running_ecs 2> /dev/null || echo "invalid")
need_migration=false
target="invalid"
if test ! -e /app/ecs; then install -g app -o app -d /app/ecs; fi
cd /app/ecs


# ### update source
if test -e /app/bin/devupdate.sh; then
    target="devserver"
else
    if test "$ECS_GIT_COMMITID" != ""; then
        target="$ECS_GIT_COMMITID"
    fi
    # if ECS_GIT_SOURCE is different to current remote repository: delete source
    current_source=$(gosu app git config --get remote.origin.url || echo "")
    if test "$ECS_GIT_SOURCE" != "$current_source"; then
        sentry_entry "Appliance Update" "Warning: ecs has different upstream sources, will re-clone. Current: \"$current_source\", new: \"$ECS_GIT_SOURCE\"" warning
        cd /; rm -r /app/ecs; install -g app -o app -d /app/ecs; cd /app/ecs
    fi
    # clone source if currently not existing
    if test ! -e /app/ecs/ecs/settings.py; then
        last_running="invalid"
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


# ### add ecs-homepage repository to /app/ecs-homepage
if test ! -e /app/ecs-homepage; then install -g app -o app -d /app/ecs-homepage; fi
cd /app/ecs-homepage
current_source=$(gosu app git config --get remote.origin.url || echo "")
if test "$ECS_DOC_GIT_SOURCE" != "$current_source"; then
    cd /; rm -r /app/ecs-homepage
    install -g app -o app -d /app/ecs-homepage; cd /app/ecs-homepage
fi
if test ! -e /app/ecs-homepage/index.html; then
    gosu app git clone --branch master $ECS_DOC_GIT_SOURCE /app/ecs-homepage
fi
gosu app git fetch -a -p
gosu app git checkout -f master
gosu app git reset --hard $(gosu app git rev-parse origin/master)
# ### copy /app/ecs-homepage/user-manual-de to /app/ecs/static/help
if test -e /app/ecs/static/help; then rm -r /app/ecs/static/help; fi
cp -Ra /app/ecs-homepage/user-manual-de/ /app/ecs/static/help


# ### rebuild images
cd /app/etc/ecs
printf "%s" "invalid" > /app/etc/tags/last_build_ecs

appliance_status "Appliance Update" "Pulling base images"
for n in redis:3 memcached tomcat:8-jre8 ubuntu:xenial; do
    docker pull $n
done

if test -e /app/etc/rebuild_wanted_ecs -o \
    "$last_running" = "devserver" -o \
    "$target" != "$last_running"; then

    if test -e /app/etc/rebuild_wanted_ecs; then
        rm /app/etc/rebuild_wanted_ecs
    fi
    appliance_status "Appliance Update" "Building ECS $target (current= $last_running)"
    if ! docker-compose build mocca pdfas ecs.web; then
        sentry_entry "Appliance Update" "ECS build failed" error
        if test "$last_running" = "invalid"; then
            appliance_exit "Appliance Error" "ECS build $target failed and no old build found, standby"
        fi
        appliance_status "Appliance Update" "ECS build failed, restarting old image"
        exit 0
    fi
    appliance_status "Appliance Update" "ECS build complete, starting ecs"
else
    appliance_status "Appliance Update" "ECS Last version = current version = $last_running, skipping build"
    exit 0
fi
printf "%s" "$target" > /app/etc/tags/last_build_ecs


# ### migrate database
if $need_migration; then
    docker-compose stop
    appliance_status "Appliance Update" "Pgdump ${ECS_DATABASE} database"
    dbdump=/data/ecs-pgdump/${ECS_DATABASE}-migrate.pgdump
    if gosu app pg_dump --encoding="utf-8" --format=custom -Z6 -f ${dbdump}.new -d $ECS_DATABASE; then
        mv ${dbdump}.new ${dbdump}
    else
        appliance_failed "Appliance Error" "Could not pgdump database $ECS_DATABASE before starting migration"
    fi
    appliance_status "Appliance Update" "Migrating ecs database"
    (docker images -q ecs/ecs:latest || echo "invalid") > /app/etc/tags/last_running_ecs_image
    printf "%s" "$target" > /app/etc/tags/last_running_ecs
    docker-compose run --no-deps --rm --name ecs.migration ecs.web migrate
    err=$?
    if test $err -ne 0; then
        appliance_failed "Appliance Error" "Migration Error"
    fi
else
    printf "%s" "$target" > /app/etc/tags/last_running_ecs
fi
