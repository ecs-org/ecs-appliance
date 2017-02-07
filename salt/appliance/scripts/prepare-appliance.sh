#!/bin/bash
. /usr/local/share/appliance/appliance.include
. /usr/local/share/appliance/prepare-storage.sh
. /usr/local/share/appliance/prepare-extra.sh
. /usr/local/share/appliance/prepare-postgresql.sh
. /usr/local/share/appliance/prepare-metric.sh
. /usr/local/share/appliance/prepare-backup.sh
. /usr/local/share/appliance/prepare-ssl.sh

set -o pipefail

# set hostname from env if different
if test "$APPLIANCE_DOMAIN" != "$(hostname -f)"; then
    echo "setting hostname to $APPLIANCE_DOMAIN"
    hostnamectl set-hostname $APPLIANCE_DOMAIN
fi

appliance_status "Appliance Startup" "Starting up"
systemctl enable nginx
systemctl start nginx

# ### storage setup
prepare_storage

# ### storagevault keys setup
prepare_storagevault

# ### write out extra files from env
prepare_extra_files

# ### database setup
prepare_database
prepare_postgresql

# ### metric collection
prepare_metric

# ### backup setup
prepare_backup

# ### ssl setup
prepare_ssl

# ### postfix: rewrite postfix main.cf with APPLIANCE_DOMAIN, restart postfix (ssl keys change)
sed -i.bak  "s/^myhostname.*/myhostname = $APPLIANCE_DOMAIN/;s/^mydomain.*/mydomain = $APPLIANCE_DOMAIN/" /etc/postfix/main.cf
if ! diff -q /etc/postfix/main.cf /etc/postfix/main.cf.bak; then
    echo "postfix configuration changed"
fi
systemctl restart postfix

# ### stunnel: restart stunnel with new keys
systemctl restart stunnel

# ### nginx: set identity and client cert config and restart
if is_truestr "${APPLIANCE_SSL_CLIENT_CERTS_MANDATORY:-false}"; then
    client_certs="on"
else
    client_certs="optional"
fi
cat /app/etc/template.identity |
    sed "s/##ALLOWED_HOSTS##/$APPLIANCE_DOMAIN/g;s/##VERIFY_CLIENT##/$client_certs/g" > /app/etc/server.identity
systemctl reload-or-restart nginx
