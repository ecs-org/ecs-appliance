#!/bin/bash

nginx_redirect_to_status "Appliance Startup" "starting up ecs"

+ find target release, either from requested or update from branch id (or leave alone if devserver)
+ find last running id on appliance, differences and needs:
  + get commit hash from /etc/appliance/ecs-commit-id|d('invalid')
  + if invalid: need-migrate=true
  + if exists devserver traces: needs-migrate=false
  + checkout ecs if not checked out to /app/ecs
  + if not exists devserver traces:
    + find differences between last running and requested and migration diff found:
        + needs-migrate=true

+ compose build ecs.*
+ compose stop ecs.*
+ migration needed: yes: database-migrate
    + if old PRE_MIGRATE snapshot exists, delete
    + snapshot ecs-database to "PRE_MIGRATE" snapshot
    + stop ecs.*
    + build new ecs
    + start ecs.web with migrate
    + add a onetime cronjob to delete PRE_MIGRATE snapshot after 1 week (which can fail if removed in the meantime)


systemd-run: compose start new ecs.*
post_start: nginx_redirect_to_status --disable
