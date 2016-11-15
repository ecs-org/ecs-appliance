#!/bin/sh
/usr/local/sbin/unchanged_cert_as_root.sh "$@"
systemctl reload-or-restart nginx
systemctl restart stunnel
systemctl restart postfix
