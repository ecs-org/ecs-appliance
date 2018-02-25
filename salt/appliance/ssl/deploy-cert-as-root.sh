#!/bin/sh
. /usr/local/share/appliance/prepare-metric.sh
simple_metric letsencrypt_last_update counter "timestamp-epoch-seconds since last update to letsencrypt" $(date +%s)

cert_metric=""
for i in $(cat /app/etc/dehydrated/domains.txt | sed -r "s/([^ ]+).*/\1/g"); do
    cert_file=/app/etc/dehydrated/certs/$i/cert.pem
    valid_until=$(openssl x509 -in $cert_file -enddate -noout | sed -r "s/notAfter=(.*)/\1/g")
    new_metric=$(mk_metric letsencrypt_valid_until gauge "timestamp-epoch-seconds of certificate validity end date" $(date --date="$valid_until" +%s) "domain=\"$i\""; printf "\n")
    cert_metric="$cert_metric
$new_metric"
done
metric_export letsencrypt_valid_until "$cert_metric"

/usr/local/sbin/unchanged-cert-as-root.sh "$@"
systemctl reload-or-restart nginx
systemctl restart stunnel
systemctl restart postfix
