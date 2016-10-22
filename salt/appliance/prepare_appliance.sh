#!/bin/bash

nginx_redirect_to_status () {
    # call(Title, Text)
    # or call("--disable")
    local templatefile=/etc/appliance/app-template.html
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


# start nginx (may be disabled by devupate.sh if on the same machine)
systemctl enable nginx
systemctl start nginx
appliance_startup

# read userdata
. /usr/local/etc/env.include
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    err=$(printf "error reading userdata: %s" `echo "$userdata_yaml"| grep USERDATA_ERR`)
    nginx_redirect_to_status "Appliance Error" "$err"
    exit 1
fi
echo -n "found user-data type: "
printf '%s' "$userdata_yaml" | grep USERDATA_TYPE
echo "write userdata to /app/active-env.yml"
printf "%s" "$userdata_yaml" > /app/active-env.yml
# export yaml into environment
ENV_YML=/app/active-env.yml update_env_from_userdata

# check if standby is true
if test "$($APPLIANCE_STANDBY| tr A-Z a-z)" = "true"; then
    nginx_redirect_to_status "Appliance Standby" "Appliance is in standby, please contact sysadmin"
    exit 1
fi

# storage setup
need_storage_setup=false
if test ! -d "/volatile/ecs-cache"; then
    echo "warning: cloud not find directory ecs-cache on /volatile"
    need_storage_setup=true
fi
if test ! -d "/data/ecs-storage-vault"; then
    echo "warning: could not find directory ecs-storage-vault on /data"
    need_storage_setup=true
fi
if test "$(findmnt -S "LABEL=ecs-volatile" -f -l -n -o "TARGET")" = ""; then
    if test "$($APPLIANCE_STORAGE_IGNORE_VOLATILE | tr A-Z a-z)" != "true"; then
        echo "warning: could not find mount for ecs-volatile filesystem"
        need_storage_setup=true
    fi
fi
if test "$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")" = ""; then
    if test "$($APPLIANCE_STORAGE_IGNORE_DATA | tr A-Z a-z)" != "true"; then
        echo "warning: could not find mount for ecs-data filesystem"
        need_storage_setup=true
    fi
fi
if $need_storage_setup; then
    echo "calling appliance.storage setup"
    salt-call state.sls appliance.storage
    err=$?
    if test "$err" -ne 0; then
        errstr="Storage Setup: Error, appliance.storage setup failed with error: $err"
        nginx_redirect_to_status "Appliance Error" "$errstr"
        exit 1
    fi
fi

# postgres data check
+ look if ecs databse is there and not empty
    + no postgres-data or postgres-data but database is not existing: goto standby
    nginx_redirect_to_status "Appliance Standby" "Appliance is in standby, no postgres-data"
    exit 1

if test "$(${APPLIANCE_LETSENCRYPT_ENABLED:-true}|tr A-Z a-z)" = "true"; then
    # generate certificates using letsencrypt (dehydrated client)
    domains_file=/etc/appliance/dehydrated/domains.txt
    if test -e $domains_file; then rm $domains_file; fi
    for domain in $APPLIANCE_HOST_NAMES; do
        printf "%s" "$domain" >> $domains_file
    done
    dehydrated -c
    echo "FIXME: currently > 1 domains overwrites other domains, last wins"
    for domain in $APPLIANCE_HOST_NAMES; do
        ln -sf /etc/appliance/server.key.pem /etc/appliance/dehydrated/certs/$domain/privkey.pem
        ln -sf /etc/appliance/server.cert.pem /etc/appliance/dehydrated/certs/$domain/fullchain.pem
    done
else
    echo "warning: letsencrypt disabled, symlink snakeoil.* to appliance/server*"
    ln -sf /etc/appliance/server.cert.pem /etc/ssl/certs/ssl-cert-snakeoil.pem
    ln -sf /etc/appliance/server.key.pem /etc/ssl/private/ssl-cert-snakeoil.key
fi

# export vault keys
printf "%s" "$APPLIANCE_VAULT_ENCRYPT" > /etc/appliance/storagevault_encrypt.sec
printf "%s" "$APPLIANCE_VAULT_SIGN" > /etc/appliance/storagevault_sign.sec

# create ready to use /root/.gpg for duply
if test -d /root/.gpg; then rm -r /root/.gpg; fi
printf "%s" "$APPLIANCE_BACKUP_ENCRYPT" > /root/.gpg/backup_encrypt.sec
chmod "0600" -r /root/.gpg/
gpg --homedir /root/.gpg --batch --yes --import /root/.gpg/backup_encrypt.sec

# reload postfix with keys
+ rewrite authorative_domain, ssl certs
+ restart postfix

# re-generate dhparam.pem if not found or less than 2048 bit
if test ! -e /etc/appliance/dhparam.pem -o "$(stat -L -c %s /etc/appliance/dhparam.pem)" -lt 224; then
    echo "no or to small dh.param found, regenerating with 2048 bit (takes a few minutes)"
    mkdir -p /etc/appliance
    openssl dhparam 2048 -out /etc/appliance/dhparam.pem
fi

# reload nginx with new identity
cat /etc/appliance/template.identity |
    sed -re "s/##domains##/$APPLIANCE_HOST_NAMES/g" > /etc/appliance/server.identity
systemctl reload-or-restart nginx


# update all packages
nginx_redirect_to_status "Appliance Update Packages" "system packages update, please wait"
echo "fixme: update all packages"
appliance_startup
