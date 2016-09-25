#!/bin/bash

nginx_redirect_to_status () {
    # call(Title, Text)
    # or call("--disable")
    if test "$1" = "--disable"; then
        
    else
        echo "nginx redirect to: $1 $2"
        cat /etc/nginx/system/template.html | sed -re /
    fi
}

appliance_startup () {
    nginx_redirect_to_status "Appliance Startup" "starting up, please wait"
}

# activate nginx, display "in startup"
systemctl start nginx
appliance_startup


# read userdata
. /usr/local/etc/env.include
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    err=$(printf "error reading userdata: %s" "$userdata_yaml"| grep USERDATA_ERR)
    nginx_redirect_to_status "Appliance Error" "$err"
    exit 1
fi
# write to /app/active-env.yml
printf "%s" "$userdata_yaml" > /app/active-env.yml
# activate all yaml into environment
ENV_YML=/app/active-env.yml update_env_from_userdata


# check if standby is true
if test "$($APPLIANCE_STANDBY| tr A-Z a-z)" = "true"; then
    nginx_redirect_to_status "Appliance Standby" "Appliance is in standby, please contact sysadmin"
    exit 1
fi


# update all packages
nginx_redirect_to_status "Appliance Update Packages" "system packages update, please wait"
echo "fixme: update all packages"
appliance_startup

# storage setup
volatile_mount=$(findmnt -S "LABEL=ecs-volatile" -f -l -n -o "TARGET")
data_mount=$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")
ignore_volatile="$($APPLIANCE_STORAGE_IGNORE_VOLATILE | tr A-Z a-z)"
ignore_data="$($APPLIANCE_STORAGE_IGNORE_DATA | tr A-Z a-z)"

if test "$volatile_mount" = "" -a  "$ignore_volatile" != "true" -o "$data_mount" = "" -a "$ignore_data" != "true"; then
    if test "$volatile_mount" = "" -a "$ignore_volatile" != "true" then
        echo "warning: could not find mount for ecs-volatile filesystem"
    fi
    if test "$data_mount" = "" -a "$ignore_data" != "true" then
        echo "warning: could not find mount for ecs-data filesystem"
    fi
    if test -z "$storage_setup"; then
        errstr="Storage Setup: Error, empty or nonexisting ECS_STORAGE_SETUP, but storage is not ready"
        nginx_redirect_to_status "Appliance Error" "$errstr"
        exit 1
    else
        echo "calling appliance.storage setup"
        salt-call state.sls appliance.storage
        err=$?
        if test "$err" -ne 0; then
            errstr="Storage Setup: Error, appliance.storage setup failed with error: $err"
            nginx_redirect_to_status "Appliance Error" "$errstr"
            exit 1
        fi
    fi
fi


# generate certificates using letsencrypt (dehydrated client)
domains_file=/usr/local/etc/dehydrated/domains.txt
if test -e $domains_file; then rm $domains_file; fi
for domain in $ECS_ALLOWED_HOSTS; do
    printf "%s" "$domain" >> $domains_file
done
dehydrated -c

# re-generate dhparam.pem if not found or less than 2048 bit
if test ! -e /etc/nginx/certs/dhparam.pem -o "$(stat -L -c %s /etc/nginx/certs/dhparam.pem)" -lt 224; then
    mkdir -p /etc/nginx/certs
    echo "no, or to small dh.param found, regenerating with 2048 bit (takes a few minutes)"
    openssl dhparam 2048 -out /etc/nginx/certs/dhparam.pem
fi


# postgres setup
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


# start ecs
+ compose start ecs.* container
+ enable crontab entries (into container crontabs)
+ change nginx config, reload
nginx_redirect_to_status --disable
