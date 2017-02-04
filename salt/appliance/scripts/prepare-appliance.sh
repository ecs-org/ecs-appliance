#!/bin/bash
. /usr/local/share/appliance/appliance.include
set -o pipefail

# set hostname from env if different
if test "$APPLIANCE_DOMAIN" != "$(hostname -f)"; then
    echo "setting hostname to $APPLIANCE_DOMAIN"
    hostnamectl set-hostname $APPLIANCE_DOMAIN
fi

appliance_status "Appliance Startup" "Starting up"
# enable and start nginx (may be disabled by devupate.sh if on the same machine)
systemctl enable nginx
systemctl start nginx

# ### storage setup
need_storage_setup=false
for d in /data/etc /data/ecs-ca /data/ecs-gpg /data/ecs-pgdump \
    /data/ecs-storage-vault /data/postgresql /volatile/docker \
    /volatile/ecs-backup-test /volatile/ecs-cache /volatile/redis \
    /volatile/prometheus /volatile/alertmanager /volatile/grafana; do
    if test ! -d $d ; then
        echo "Warning: could not find directory $d"
        need_storage_setup=true
    fi
done
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
        appliance_failed "Appliance Error" "Storage Setup: Error, appliance.storage setup failed with error: $err"
    fi
fi

# ### write out extra files from env
if test "$APPLIANCE_EXTRA_FILES_LEN" != ""; then
    for i in $(seq 0 $(( $APPLIANCE_EXTRA_FILES_LEN -1 )) ); do
        fieldname="APPLIANCE_EXTRA_FILES_${i}_PATH"; fname="${!fieldname}"
        fieldname="APPLIANCE_EXTRA_FILES_${i}_OWNER"; fowner="${!fieldname}"
        fieldname="APPLIANCE_EXTRA_FILES_${i}_PERMISSIONS"; fperm="${!fieldname}"
        fieldname="APPLIANCE_EXTRA_FILES_${i}_CONTENT"; fcontent="${!fieldname}"
        echo "$fcontent" > $fname
        if test "$fowner" != ""; then chown $fowner $fname; fi
        if test "$fperm" != ""; then chmod $fperm $fname; fi
    done
fi

# ### database setup
gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw "$ECS_DATABASE"
if test $? -ne 0; then
    appliance_failed "Appliance Standby" "Appliance is in standby, no postgresql database named $ECS_DATABASE"
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
pgpass=$(cat /app/etc/ecs/database_url.env 2> /dev/null | grep 'DATABASE_URL=' | \
    sed -re 's/DATABASE_URL=postgres:\/\/[^:]+:([^@]+)@.+/\1/g')
if test "$pgpass" = ""; then pgpass="invalid"; fi
if test "$pgpass" = "invalid"; then
    # set app user postgresql password to a random string and write to service_urls.env
    pgpass=$(HOME=/root openssl rand -hex 8)
    gosu postgres psql -c "ALTER ROLE app WITH ENCRYPTED PASSWORD '"${pgpass}"';"
    sed -ri "s/(postgres:\/\/app:)[^@]+(@[^\/]+\/).+/\1${pgpass}\2${ECS_DATABASE}/g" /app/etc/ecs/database_url.env
    # DATABASE_URL=postgres://app:invalidpassword@1.2.3.4:5432/ecs
fi
tune_postgresql


# ### metric collection
# set/clear flags and start/stop services connected to flags
services="cadvisor.service node-exporter.service postgres_exporter.service process-exporter.service"
if is_truestr "$APPLIANCE_METRIC_EXPORTER"; then
    flag_and_service_enable "metric.exporter" "$services"
else
    flag_and_service_disable "metric.exporter" "$services"
fi
services="prometheus.service alertmanager.service"
if is_truestr "$APPLIANCE_METRIC_SERVER"; then
    flag_and_service_enable "metric.server" "$services"
else
    flag_and_service_disable "metric.server" "$services"
fi
if is_truestr "$APPLIANCE_METRIC_GUI"; then
    flag_and_service_enable "metric.gui" "grafana.service"
else
    flag_and_service_disable "metric.gui" "grafana.service"
fi
if is_truestr "$APPLIANCE_METRIC_PGHERO"; then
    flag_and_service_enable "metric.pghero" "pghero-container.service"
else
    flag_and_service_disable "metric.pghero" "pghero-container.service"
fi

# ### storagevault keys setup
echo "writing storage vault keys to ecs-gpg"
# wipe directory clean of *.gpg files, but not eg. random_seed and do not remove directory
find /data/ecs-gpg -mindepth 1 -name "*.gpg*" -delete
echo "$ECS_VAULT_ENCRYPT" | gpg --homedir /data/ecs-gpg --batch --yes --import --
echo "$ECS_VAULT_SIGN" | gpg --homedir /data/ecs-gpg --batch --yes --import --
chown -R 1000:1000 /data/ecs-gpg

# ### backup setup
# create ready to use /root/.gnupg for backup being done using duplicity
mkdir -p /root/.gnupg
find /root/.gnupg -mindepth 1 -name "*.gpg*" -delete
echo "$APPLIANCE_BACKUP_ENCRYPT" | gpg --homedir /root/.gnupg --batch --yes --import --
# write out backup target and gpg_key to duply config
gpg_key_id=$(gpg --keyid-format 0xshort --list-key ecs_backup | grep pub | sed -r "s/pub.+0x([0-9A-F]+).+/\1/g")
cat /root/.duply/appliance-backup/conf.template | \
    sed -r "s#^TARGET=.*#TARGET=$APPLIANCE_BACKUP_URL#;s#^GPG_KEY=.*#GPG_KEY=$gpg_key_id#" > \
    /root/.duply/appliance-backup/conf

# ### ssl setup
# re-generate dhparam.pem if not found or less than 2048 bit
recreate_dhparam=$(test ! -e /app/etc/dhparam.pem && echo "true" || echo "false")
if ! $recreate_dhparam; then
    recreate_dhparam=$(test "$(stat -L -c %s /app/etc/dhparam.pem)" -lt 224 && echo "true" || echo "false")
fi
if $recreate_dhparam; then
    echo "no or to small dh.param found, regenerating with 2048 bit (takes a few minutes)"
    mkdir -p /app/etc
    openssl dhparam 2048 -out /app/etc/dhparam.pem
fi
# certificate setup
use_snakeoil=true
domains_file=/app/etc/dehydrated/domains.txt
if test "${APPLIANCE_SSL_KEY}" != "" -a "${APPLIANCE_SSL_CERT}" != ""; then
    echo "Information: using ssl key,cert supplied from environment"
    printf "%s" "${APPLIANCE_SSL_KEY}" > /app/etc/server.key.pem
    printf "%s" "${APPLIANCE_SSL_CERT}" > /app/etc/server.cert.pem
    cat /app/etc/server.cert.pem /app/etc/dhparam.pem > /app/etc/server.cert.dhparam.pem
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
    cp /app/etc/snakeoil/ssl-cert-snakeoil.pem /app/etc/server.cert.pem
    cp /app/etc/snakeoil/ssl-cert-snakeoil.key /app/etc/server.key.pem
    cat /app/etc/server.cert.pem /app/etc/dhparam.pem > /app/etc/server.cert.dhparam.pem
fi

# rewrite postfix main.cf with APPLIANCE_DOMAIN, restart postfix (ssl keys could be changed)
sed -i.bak  "s/^myhostname.*/myhostname = $APPLIANCE_DOMAIN/;s/^mydomain.*/mydomain = $APPLIANCE_DOMAIN/" /etc/postfix/main.cf
if ! diff -q /etc/postfix/main.cf /etc/postfix/main.cf.bak; then
    echo "postfix configuration changed"
fi
systemctl restart postfix

# restart stunnel with new keys
systemctl restart stunnel

# reload nginx with new identity and client cert config
if is_truestr "${APPLIANCE_SSL_CLIENT_CERTS_MANDATORY:-false}"; then
    client_certs="on"
else
    client_certs="optional"
fi
cat /app/etc/template.identity |
    sed "s/##ALLOWED_HOSTS##/$APPLIANCE_DOMAIN/g;s/##VERIFY_CLIENT##/$client_certs/g" > /app/etc/server.identity
systemctl reload-or-restart nginx
