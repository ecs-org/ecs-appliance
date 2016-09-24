#!/bin/bash

# activate nginx, display "in startup"
nginx_redirect_default starting.html
if (get cert,self-sign if fail) display simple http&s page: Service not available
systemctl start nginx


# read userdata
. /usr/local/etc/env.include
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    echo -n "error reading userdata: "
    printf "%s" "$userdata_yaml"| grep USERDATA_ERR
    # display error about missing userdata
    nginx_redirect_default no-userdata.html
    systemctl reload nginx
    exit 1
fi
# write to /app/active-env.yml
printf "%s" "$userdata_yaml" > /app/active-env.yml


# update all packages
nginx_redirect_default update-in-progress.html
echo "fixme: update all packages"


# letsencrypt setup
domains=$(ENV_YML=/app/active-env.yml userdata_to_envlist ecs |
    grep ECS_ALLOWED_HOSTS | sed -re "s/[^=]+=(.+)/\1/")
domains_file=/usr/local/etc/dehydrated/domains.txt
if test -e $domains_file; then rm $domains_file; fi
for domain in $domains; do
    printf "%s" "$domain" >> $domains_file
done
dehydrated -c


# check if standby is true
standby=$(ENV_YML=/app/active-env.yml userdata_to_envlist appliance |
    grep APPLIANCE_STANDBY | sed -re "s/[^=]+=(.+)/\1/" | tr A-Z a-z)
if test "$standby" = "true"; then
    nginx_redirect_default standby.html
    exit 1
fi


# storage setup
storage=$(ENV_YML=/app/active-env.yml userdata_to_envlist appliance | grep APPLIANCE_STORAGE)
ignore_volatile=$(printf "%s" $storage | grep _IGNORE_VOLATILE | sed -re "s/[^=]+=(.+)/\1/" | tr A-Z a-z)
ignore_data=$(printf "%s" $storage | grep _IGNORE_DATA | sed -re "s/[^=]+=(.+)/\1/" | tr A-Z a-z)
storage_setup=$(printf "%s" $storage | grep STORAGE_SETUP | sed -re "s/[^=]+=(.+)/\1/")
volatile_mount=$(findmnt -S "LABEL=ecs-volatile" -f -l -n -o "TARGET")
data_mount=$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")

if test "$volatile_mount" = "" -a "$ignore_volatile" != "true" -o "$data_mount" = "" -a "$ignore_data" != "true"; then
    if test "$volatile_mount" = "" -a "$ignore_volatile" != "true"; then
        echo "error finding mount for ecs-volatile filesystem"
    fi
    if test "$data_mount" = "" -a "$ignore_data" != "true"; then
        echo "error finding mount for ecs-data filesystem"
    fi
    if test -z "$storage_setup"; then
        echo "error, empty or nonexisting ECS_STORAGE_SETUP, but storage is not ready"
        nginx_redirect_default no-storage.html
        exit 1
    else
        salt-call state.sls appliance.storage
        err=$?
        if test "$err" -ne 0; then
            echo "error, appliance.storage_setup returned error: $err"
            nginx_redirect_default no-storage.html
            exit 1
        fi
    fi
fi



+ look if postgres-data is found /data/postgres-ecs/*
+ start local postgres
+ no postgres-data or postgres-data but database is empty:
    + ECS_RECOVER_FROM_BACKUP ?
        + yes: duplicity restore to /data/ecs-files and /tmp/pgdump
    + ECS_RECOVER_FROM_DUMP ?
        + yes: pgimport from pgdump
    + restored from somewhere ?
        + premigrate (if old dump) and migrate
    + not restored from dump ?
        + yes: create new database


+ compose start ecs.* container
+ change nginx config, reload
nginx_redirect_default --disable



### start errors
    + recover_from_backup but error while duplicity restore/connect ("recover from backup error")
