#!/bin/sh
. /usr/local/share/appliance/prepare-metric.sh
simple_metric letsencrypt_last_update counter "timestamp-epoch-seconds since last update to letsencrypt" $(date +%s)
/usr/local/sbin/unchanged-cert-as-root.sh "$@"
systemctl reload-or-restart nginx
systemctl restart stunnel
systemctl restart postfix
