#!/bin/bash

. /usr/local/etc/env.include
. /usr/local/etc/appliance.include
ECS_DATABASE=${ECS_DATABASE:-ecs}

appliance_status_starting
# enable and start nginx (may be disabled by devupate.sh if on the same machine)
systemctl enable nginx
systemctl start nginx

# ### environment setup
# read userdata
userdata_yaml=$(get_userdata)
if test $? -ne 0; then
    appliance_exit "Appliance Error" "$(printf "Error reading userdata: %s" `echo "$userdata_yaml"| grep USERDATA_ERR`)"
fi
echo -n "found user-data type: "
printf '%s' "$userdata_yaml" | grep USERDATA_TYPE
echo "write userdata to /app/active-env.yml"
printf "%s" "$userdata_yaml" > /app/active-env.yml

# export active yaml into environment
ENV_YML=/app/active-env.yml update_env_from_userdata ecs,appliance
if test $? -ne 0; then
    appliance_exit "Appliance Error" "Could not activate userdata environment"
fi

# check if standby is true
if is_truestr "$APPLIANCE_STANDBY"; then
    appliance_exit_standby
fi

# ### storage setup
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
    if is_falsestr "$APPLIANCE_STORAGE_IGNORE_VOLATILE"; then
        echo "warning: could not find mount for ecs-volatile filesystem"
        need_storage_setup=true
    fi
fi
if test "$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")" = ""; then
    if is_falsestr "$APPLIANCE_STORAGE_IGNORE_DATA"; then
        echo "warning: could not find mount for ecs-data filesystem"
        need_storage_setup=true
    fi
fi
if $need_storage_setup; then
    echo "calling appliance.storage setup"
    salt-call state.sls appliance.storage
    err=$?
    if test "$err" -ne 0; then
        appliance_exit "Appliance Error" "Storage Setup: Error, appliance.storage setup failed with error: $err"
    fi
fi

# ### database setup
gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw "$ECS_DATABASE"
if test $? -ne 0; then
    appliance_exit "Appliance Standby" "Appliance is in standby, no postgresql database named $ECS_DATABASE"
fi
if ! $(gosu postgres psql -c "\dg;" | grep app -q); then
    # create role app
    gosu postgres createuser app
fi
owner=$(gosu postgres psql -qtc "\l" | grep "^[ \t]*${ECS_DATABASE}" | sed -re "s/[^|]+|([^|]+)|.*/\1/")
if test "$owner" != "app"; then
    # set owner of ECS_DATABASE to app
    gosu postgres psql -c "ALTER DATABASE ${ECS_DATABASE} OWNER TO app;"
fi
if ! $(gosu postgres psql ${ECS_DATABASE} -qtc "\dx" | grep -q pg_stat_statements); then
    # create pg_stat_statements extension
    gosu postgres psql ${ECS_DATABASE} -c "CREATE extension pg_stat_statements;"
fi
# modify app user postgresql password to random 8byte hex string
pgpass=$(HOME=/root openssl rand -hex 8)
gosu postgres psql -c "ALTER ROLE app WITH ENCRYPTED PASSWORD '"${pgpass}"';"

# write out service_urls for docker-compose
cat > /etc/appliance/ecs/service_urls.env << EOF
REDIS_URL=redis://ecs_redis_1:6379/0
MEMCACHED_URL=memcached://ecs_memcached_1:11211
DATABASE_URL=postgres://app:${pgpass}@${dockerip}:5432/${ECS_DATABASE}
EOF

# export vault keys from env to /etc/appliance
printf "%s" "$APPLIANCE_VAULT_ENCRYPT" > /etc/appliance/storagevault_encrypt.sec
printf "%s" "$APPLIANCE_VAULT_SIGN" > /etc/appliance/storagevault_sign.sec

# create ready to use /root/.gpg for backup being done using duplicity
if test -d /root/.gpg; then rm -r /root/.gpg; fi
mkdir -p /root/.gpg
printf "%s" "$APPLIANCE_BACKUP_ENCRYPT" > /root/.gpg/backup_encrypt.sec
chmod -R 0600 /root/.gpg/
gpg --homedir /root/.gpg --batch --yes --import /root/.gpg/backup_encrypt.sec

# ### ssl setup
# re-generate dhparam.pem if not found or less than 2048 bit
recreate_dhparam=$(test ! -e /etc/appliance/dhparam.pem && echo "true" || echo "false")
if ! $recreate_dhparam; then
    recreate_dhparam=$(test "$(stat -L -c %s /etc/appliance/dhparam.pem)" -lt 224 && echo "true" || echo "false")
fi
if $recreate_dhparam; then
    echo "no or to small dh.param found, regenerating with 2048 bit (takes a few minutes)"
    mkdir -p /etc/appliance
    openssl dhparam 2048 -out /etc/appliance/dhparam.pem
fi
# certificate setup
use_snakeoil=true
if test "${APPLIANCE_SSL_KEY}" != "" -a test "${APPLIANCE_SSL_CERT}" != ""; then
    echo "Information: using ssl key,cert supplied from environment"
    printf "%s" "${APPLIANCE_SSL_KEY}" > /etc/appliance/server.key.pem
    printf "%s" "${APPLIANCE_SSL_CERT}" > /etc/appliance/server.cert.pem
    cat /etc/appliance/server.cert.pem /etc/appliance/dhparam.pem > /etc/appliance/server.cert.dhparam.pem
    use_snakeoil=false
fi
domains_file=/etc/appliance/dehydrated/domains.txt
if test -e $domains_file; then rm $domains_file; fi
if is_truestr "${APPLIANCE_SSL_LETSENCRYPT_ENABLED:-true}"; then
    echo "Information: generate certificates using letsencrypt (dehydrated client)"
    printf "%s" "$APPLIANCE_DOMAIN" > $domains_file
    gosu app dehydrated -c
    if test "$?" -eq 0; then
        use_snakeoil=false
    else
        echo "Warning: letsencrypt client (dehydrated) returned an error"
    fi
fi
if $use_snakeoil; then
    echo "warning: letsencrypt disabled, symlink snakeoil.* to appliance/server*"
    ln -sf /etc/appliance/server.cert.pem /etc/appliance/ssl-cert-snakeoil.pem
    ln -sf /etc/appliance/server.key.pem /etc/appliance/ssl-cert-snakeoil.key
    cat /etc/appliance/server.cert.pem /etc/appliance/dhparam.pem > /etc/appliance/server.cert.dhparam.pem
fi

# reload postfix with keys
echo "fixme: postfix: rewrite domain, ssl certs, restart"

# reload stunnel with keys
echo "fixme: stunnel: rewrite domain, ssl certs, restart"

# reload nginx with new identity and client cert config
if is_truestr "${APPLIANCE_SSL_CLIENT_CERTS_MANDATORY:-false}"; then
    client_certs="on"
else
    client_certs="optional"
fi
cat /etc/appliance/template.identity |
    sed -re "s/##ALLOWED_HOSTS##/$APPLIANCE_ALLOWED_HOSTS/g" |
    sed -re "s/##VERIFY_CLIENT##/$client_certs/g"> /etc/appliance/server.identity
systemctl reload-or-restart nginx

# update all packages
appliance_status "Appliance Update" "Update system packages"
echo "fixme: update all packages"
appliance_status_starting
