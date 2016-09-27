#!/bin/bash

nginx_redirect_to_status () {
    # call(Title, Text)
    # or call("--disable")
    local templatefile=/etc/nginx/app/app-template.html
    local resultfile=/var/www/html/app.html
    local title text
    if test "$1" = "--disable"; then
        if test -e $resultfile; then
            rm -f $resultfile
        fi
    else
        echo "nginx redirect to: $1 $2"
        title=$(echo "$1" | tr / \\/)
        text=$(echo "$2" | tr / \\/)
        cat $templatefile |
            sed -re "s/\{\{ ?title ?\}\}/$title/g" |
            sed -re "s/\{\{ ?text ?\}\}/$text/g" > $resultfile
    fi
}

appliance_startup () {
    nginx_redirect_to_status "Appliance Startup" "starting up, please wait"
}


# display "in startup"
appliance_startup

# read userdata
. /usr/local/etc/env.include
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    err=$(printf "error reading userdata: %s" `echo "$userdata_yaml"| grep USERDATA_ERR`)
    nginx_redirect_to_status "Appliance Error" "$err"
    exit 1
fi
# write userdata to /app/active-env.yml
printf "%s" "$userdata_yaml" > /app/active-env.yml
# export yaml into environment
ENV_YML=/app/active-env.yml update_env_from_userdata

# check if standby is true
if test "$($APPLIANCE_STANDBY| tr A-Z a-z)" = "true"; then
    nginx_redirect_to_status "Appliance Standby" "Appliance is in standby, please contact sysadmin"
    exit 1
fi

# storage setup
volatile_mount=$(findmnt -S "LABEL=ecs-volatile" -f -l -n -o "TARGET")
data_mount=$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")
ignore_volatile="$($APPLIANCE_STORAGE_IGNORE_VOLATILE | tr A-Z a-z)"
ignore_data="$($APPLIANCE_STORAGE_IGNORE_DATA | tr A-Z a-z)"
need_storage_setup="false"

if test "$volatile_mount" = ""; then
    if test "$ignore_volatile" != "true" then
        echo "warning: could not find mount for ecs-volatile filesystem"
        need_storage_setup = "true"
    fi
else
    if test ! -d "/volatile/ecs-cache"; then
        echo "warning: cloud not find ecs-cache on volatile filesystem"
        need_storage_setup = "true"
    fi
fi
if test "$data_mount" = ""; then
    if test "$ignore_data" != "true" then
        echo "warning: could not find mount for ecs-data filesystem"
        need_storage_setup = "true"
    fi
else
    if test ! -d "/data/ecs-storage-vault"; then
        echo "warning: could not find ecs-storage-vault on data filesystem"
        need_storage_setup = "true"
    fi
fi
if test "$need_storage_setup" = "true"; then
    if test -z "$APPLIANCE_STORAGE_SETUP"; then
        if test "$ignore_volatile" != "true" -o "$ignore_data" != "true"; then
            errstr="Storage Setup: Error, empty or nonexisting APPLIANCE_STORAGE_SETUP, but storage is not ready"
            nginx_redirect_to_status "Appliance Error" "$errstr"
            exit 1
        fi
    fi
    echo "calling appliance.storage setup"
    salt-call state.sls appliance.storage
    err=$?
    if test "$err" -ne 0; then
        errstr="Storage Setup: Error, appliance.storage setup failed with error: $err"
        nginx_redirect_to_status "Appliance Error" "$errstr"
        exit 1
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
if test ! -e /etc/nginx/app/dhparam.pem -o "$(stat -L -c %s /etc/nginx/app/dhparam.pem)" -lt 224; then
    mkdir -p /etc/nginx/app
    echo "no, or to small dh.param found, regenerating with 2048 bit (takes a few minutes)"
    openssl dhparam 2048 -out /etc/nginx/app/dhparam.pem
fi

# compile gpg keys into usable format
+ storage-vault keys to a .gnupg directory
+ duplicity backup key to a .gnupg directory

# reload nginx with new identity
cat /etc/nginx/app/template.identity |
    sed -re "s/##domains##/$ECS_ALLOWED_HOSTS/g" > /etc/nginx/app/server.identity
systemctl reload nginx

# update all packages
nginx_redirect_to_status "Appliance Update Packages" "system packages update, please wait"
echo "fixme: update all packages"
appliance_startup

# smtp setup
+ rewrite authorative_domain, ssl certs
+ start postfix

# postgres setup
+ start local postgres
+ look if postgres-data is found /data/postgres-ecs/*
    + no postgres-data or postgres-data but database is not existing: goto standby
    nginx_redirect_to_status "Appliance Standby" "Appliance is in standby, no postgres-data"
    exit 1

# start ecs
+ look if we find old running ecs: get commit hash
+ look if database migration is needed diff current/expected branch of *migrations*
    + yes: database-migrate
+ compose start ecs.* container
+ enable crontab entries (into container crontabs)
nginx_redirect_to_status --disable

### database-migrate
+ if old PRE_MIGRATE snapshot exists, delete
+ snapshot ecs-database to "PRE_MIGRATE" snapshot
+ start ecs.web with migrate
+ add a onetime cronjob to delete PRE_MIGRATE snapshot after 1 week (which can fail if removed in the meantime)
