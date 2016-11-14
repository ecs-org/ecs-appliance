#!/bin/sh
/usr/local/sbin/unchanged_cert_as_root.sh $1 $2 $3 $4 $5
systemctl reload-or-restart nginx
systemctl restart stunnel
systemctl restart postfix
