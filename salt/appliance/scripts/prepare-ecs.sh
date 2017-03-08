#!/bin/bash
. /usr/local/share/appliance/appliance.include
. /usr/local/share/appliance/prepare-metric.sh

start_epoch_seconds=$(date +%s)
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


# ### add ecs-docs repository to /app/ecs-docs
if test ! -e /app/ecs-docs; then install -g app -o app -d /app/ecs-docs; fi
cd /app/ecs-docs
current_source=$(gosu app git config --get remote.origin.url || echo "")
if test "$ECS_DOCS_GIT_SOURCE" != "$current_source"; then
    cd /; rm -r /app/ecs-docs
    install -g app -o app -d /app/ecs-docs; cd /app/ecs-docs
fi
if test ! -e /app/ecs-docs/index.html; then
    gosu app git clone --branch $ECS_DOCS_GIT_BRANCH $ECS_DOCS_GIT_SOURCE /app/ecs-docs
fi
gosu app git fetch -a -p
gosu app git checkout -f $ECS_DOCS_GIT_BRANCH
gosu app git reset --hard $(gosu app git rev-parse origin/$ECS_DOCS_GIT_BRANCH)
# ### copy /app/ecs-docs/user-manual-de to /app/ecs/static/help
if test -e /app/ecs/static/help; then rm -r /app/ecs/static/help; fi
cp -Ra /app/ecs-docs/user-manual-de/ /app/ecs/static/help


# ### rebuild images
cd /app/etc/ecs
printf "%s" "invalid" > /app/etc/tags/last_build_ecs

appliance_status "Appliance Update" "Pulling base images"
for n in redis:3 oliver006/redis_exporter memcached prom/memcached-exporter \
    tomcat:8-jre8 ubuntu:xenial timonwong/uwsgi-exporter; do
    docker pull $n
done

if test -e /app/etc/flags/force.update.ecs -o \
    "$last_running" = "devserver" -o \
    "$target" != "$last_running"; then

    if test -e /app/etc/flags/force.update.ecs; then
        rm /app/etc/flags/force.update.ecs
    fi
    appliance_status "Appliance Update" "Building ECS $target (current= $last_running)"
    simple_metric ecs_last_update counter "timestamp-epoch-seconds since last update to ecs" $start_epoch_seconds
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
simple_metric ecs_version gauge "ecs_version" 1 \
"git_rev=\"$(gosu app git -C /app/ecs rev-parse HEAD)\",\
git_branch=\"$(gosu app git -C /app/ecs rev-parse --abbrev-ref HEAD)\""

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
    simple_metric ecs_last_migrate counter "timestamp-epoch-seconds since last ecs database migration" $start_epoch_seconds
    (docker images -q ecs/ecs:latest || echo "invalid") > /app/etc/tags/last_running_ecs_image
    printf "%s" "$target" > /app/etc/tags/last_running_ecs
    printf "%s" "$target" > /app/etc/tags/last_migration_ecs
    docker-compose run --no-deps --rm --name ecs.migration ecs.web migrate
    err=$?
    if test $err -ne 0; then
        appliance_failed "Appliance Error" "Migration Error"
    fi
else
    printf "%s" "$target" > /app/etc/tags/last_running_ecs
    appliance_status "Appliance Update" "Running ecs bootstrap"
    docker-compose run --no-deps --rm --name ecs.bootstrap ecs.web run ./manage.py bootstrap
    err=$?
    if test $err -ne 0; then
        appliance_failed "Appliance Error" "Bootstrap Error"
    fi
fi
