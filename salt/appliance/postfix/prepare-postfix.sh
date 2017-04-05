prepare_postfix () {
    local restart_opendkim=false
    # ### opendkim: rewrite opendkim.conf with APPPLIANCE_DOMAIN
    sed -i.bak  "s/^Domain.*/Domain                 $APPLIANCE_DOMAIN/" /etc/opendkim.conf
    if ! diff -q /etc/opendkim.conf.bak /etc/opendkim.conf; then
        echo "opendkim.conf changed"
        diff -u /etc/opendkim.conf.bak /etc/opendkim.conf
        restart_opendkim=true
    fi
    # ### opendkim: rewrite rsa key if not existing or different with APPLIANCE_DKIM_KEY
    if test ! -d /etc/dkimkeys; then mkdir /etc/dkimkeys; fi
    echo "$APPLIANCE_DKIM_KEY" > /etc/dkimkeys/dkim.key.new
    chown opendkim /etc/dkimkeys/dkim.key.new
    chmod "0600" /etc/dkimkeys/dkim.key.new
    if ! diff -q /etc/dkimkeys/dkim.key /etc/dkimkeys/dkim.key.new; then
        echo "/etc/dkimkeys/dkim.key changed"
        mv /etc/dkimkeys/dkim.key.new /etc/dkimkeys/dkim.key
        restart_opendkim=true
    fi
    if $restart_opendkim; then
        systemctl restart opendkim
    fi
    # ### postfix: rewrite postfix main.cf with APPLIANCE_DOMAIN, restart postfix (ssl keys change)
    sed -i.bak  "s/^myhostname.*/myhostname = $APPLIANCE_DOMAIN/;s/^mydomain.*/mydomain = $APPLIANCE_DOMAIN/" /etc/postfix/main.cf
    if ! diff -q /etc/postfix/main.cf /etc/postfix/main.cf.bak; then
        echo "postfix main.cf changed"
        diff -u /etc/postfix/main.cf.bak /etc/postfix/main.cf
    fi
    systemctl restart postfix
}
