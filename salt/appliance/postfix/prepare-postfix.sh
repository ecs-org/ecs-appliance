prepare_postfix () {
    # ### postfix: rewrite postfix main.cf with APPLIANCE_DOMAIN, restart postfix (ssl keys change)
    sed -i.bak  "s/^myhostname.*/myhostname = $APPLIANCE_DOMAIN/;s/^mydomain.*/mydomain = $APPLIANCE_DOMAIN/" /etc/postfix/main.cf
    if ! diff -q /etc/postfix/main.cf /etc/postfix/main.cf.bak; then
        echo "postfix configuration changed"
    fi
    systemctl restart postfix
}
