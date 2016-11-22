#!/bin/bash

. /usr/local/etc/appliance.include

set -o pipefail
ECS_DATABASE=${ECS_DATABASE:-ecs}


# set hostname from env
if test "$APPLIANCE_DOMAIN" != "$(hostname -f)"; then
    echo "setting hostname to $APPLIANCE_DOMAIN"
    hostnamectl set-hostname $APPLIANCE_DOMAIN
    printf "%s" "$APPLIANCE_DOMAIN" > /etc/salt/minion_id
fi

appliance_status_starting
# enable and start nginx (may be disabled by devupate.sh if on the same machine)
systemctl enable nginx
systemctl start nginx

# ### storage setup
need_storage_setup=false
if test ! -d "/volatile/ecs-cache"; then
    echo "Warning: could not find directory ecs-cache on /volatile"
    need_storage_setup=true
fi
if test ! -d "/data/ecs-storage-vault"; then
    echo "Warning: could not find directory ecs-storage-vault on /data"
    need_storage_setup=true
fi
if test "$(findmnt -S "LABEL=ecs-volatile" -f -l -n -o "TARGET")" = ""; then
    if is_falsestr "$APPLIANCE_STORAGE_IGNORE_VOLATILE"; then
        echo "Warning: could not find mount for ecs-volatile filesystem"
        need_storage_setup=true
    fi
fi
if test "$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")" = ""; then
    if is_falsestr "$APPLIANCE_STORAGE_IGNORE_DATA"; then
        echo "Warning: could not find mount for ecs-data filesystem"
        need_storage_setup=true
    fi
fi
if $need_storage_setup; then
    echo "calling appliance.storage setup"
    salt-call state.sls appliance.storage --retcode-passthrough --return appliance
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
owner=$(gosu postgres psql -qtc "\l" |
    grep "^[ \t]*${ECS_DATABASE}" | sed -r "s/[^|]+\| +([^| ]+) +\|.*/\1/")
if test "$owner" != "app"; then
    # set owner of ECS_DATABASE to app
    gosu postgres psql -c "ALTER DATABASE ${ECS_DATABASE} OWNER TO app;"
fi
if ! $(gosu postgres psql ${ECS_DATABASE} -qtc "\dx" | grep -q pg_stat_statements); then
    # create pg_stat_statements extension
    gosu postgres psql ${ECS_DATABASE} -c "CREATE extension pg_stat_statements;"
fi
pgpass=$((cat /etc/appliance/ecs/database_url.env 2> /dev/null | grep 'DATABASE_URL=' | \
    sed -re 's/DATABASE_URL=postgres:\/\/[^:]+:([^@]+)@.+/\1/g' ) || \
    printf '%s' 'invalid')
if test "$pgpass" = "invalid"; then
    # set app user postgresql password to a random string and write to service_urls.env
    pgpass=$(HOME=/root openssl rand -hex 8)
    gosu postgres psql -c "ALTER ROLE app WITH ENCRYPTED PASSWORD '"${pgpass}"';"
    sed -ri "s/(postgres:\/\/app:)[^@]+(@[^\/]+\/).+/\1${pgpass}\2${ECS_DATABASE}/" /etc/appliance/ecs/database_url.env
    # DATABASE_URL=postgres://app:invalidpassword@1.2.3.4:5432/ecs
fi

# ### backup setup
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
domains_file=/etc/appliance/dehydrated/domains.txt
if test "${APPLIANCE_SSL_KEY}" != "" -a "${APPLIANCE_SSL_CERT}" != ""; then
    echo "Information: using ssl key,cert supplied from environment"
    printf "%s" "${APPLIANCE_SSL_KEY}" > /etc/appliance/server.key.pem
    printf "%s" "${APPLIANCE_SSL_CERT}" > /etc/appliance/server.cert.pem
    cat /etc/appliance/server.cert.pem /etc/appliance/dhparam.pem > /etc/appliance/server.cert.dhparam.pem
    use_snakeoil=false
else
    if is_truestr "${APPLIANCE_SSL_LETSENCRYPT_ENABLED:-true}"; then
        echo "Information: generate certificates using letsencrypt (dehydrated client)"
        # we need a SAN (subject alternative name) for java ssl :(
        printf "%s" "$APPLIANCE_DOMAIN $APPLIANCE_DOMAIN" > $domains_file
        gosu app dehydrated -c
        if test "$?" -eq 0; then
            use_snakeoil=false
            echo "Information: letsencrypt was successful, using letsencrypt certificate"
        else
            echo "Warning: letsencrypt client (dehydrated) returned an error"
        fi
    fi
fi
if is_falsestr "${APPLIANCE_SSL_LETSENCRYPT_ENABLED:-true}"; then
    # delete domains_file to keep cron from retrying to refresh certs
    if test -e $domains_file; then rm $domains_file; fi
fi
if $use_snakeoil; then
    echo "Warning: couldnt setup server certificate, copy snakeoil.* to appliance/server*"
    cp /etc/appliance/ssl-cert-snakeoil.pem /etc/appliance/server.cert.pem
    cp /etc/appliance/ssl-cert-snakeoil.key /etc/appliance/server.key.pem
    cat /etc/appliance/server.cert.pem /etc/appliance/dhparam.pem > /etc/appliance/server.cert.dhparam.pem
fi

# rewrite postfix main.cf with APPLIANCE_DOMAIN, restart postfix with new domain and keys
sed -i  "s/^myhostname.*/myhostname = $APPLIANCE_DOMAIN/;s/^mydomain.*/mydomain = $APPLIANCE_DOMAIN/" /etc/postfix/main.cf
systemctl restart postfix

# restart stunnel with new keys
systemctl restart stunnel

# reload nginx with new identity and client cert config
if is_truestr "${APPLIANCE_SSL_CLIENT_CERTS_MANDATORY:-false}"; then
    client_certs="on"
else
    client_certs="optional"
fi
cat /etc/appliance/template.identity |
    sed "s/##ALLOWED_HOSTS##/$APPLIANCE_DOMAIN/g;s/##VERIFY_CLIENT##/$client_certs/g" > /etc/appliance/server.identity
systemctl reload-or-restart nginx
appliance_status_starting
