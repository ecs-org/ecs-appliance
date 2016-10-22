#!/bin/bash

nginx_redirect_to_status "Appliance Startup" "starting up ecs"

#get target commit hash
if test -e /app/bin/devupdate.sh; then
    target="devserver"
elif test "$ECS_COMMIT_ID" != ""; then
    target="$ECS_COMMIT_ID"
else
    checkout ecs if not checked out to /app/ecs
    git fetch, get latest commit from branch ECS_BRANCH
fi

checkout ecs if not checked out to /app/ecs

#get last_running commit hash
if test -e /etc/appliance/ECS_COMMIT_ID; then
    last_running=$(cat /etc/appliance/ECS_COMMIT_ID || echo "invalid")
else
    last_running="invalid"
fi

if test $target = "devserver"; then
    need_migration=false
else
    if test "$last_running" = "invalid"; then
        need_migration=true
    else
        need_migration=$(git diff --name-status $last_running..origin/$target |
            grep -q "^A.*/migrations/" && echo true || echo false)
    fi
fi

cd /app/compose
docker-compose build --pull
docker-compose stop
if need_migration; then
    + migration needed: yes: database-migrate
        + if old PRE_MIGRATE snapshot exists, delete
        + snapshot ecs-database to "PRE_MIGRATE" snapshot
        + start ecs.web with migrate
        + add a onetime cronjob to delete PRE_MIGRATE snapshot after 1 week (which can fail if removed in the meantime)
fi
