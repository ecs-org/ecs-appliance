#!/bin/sh
/usr/local/sbin/unchanged-cert-as-root.sh "$@"
systemctl reload-or-restart nginx
systemctl restart stunnel
systemctl restart postfix
systemctl restart appliance
