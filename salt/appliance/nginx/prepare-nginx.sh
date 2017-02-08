prepare_nginx () {
    # ### nginx: set identity and client cert config and restart
    if is_truestr "${APPLIANCE_SSL_CLIENT_CERTS_MANDATORY:-false}"; then
        client_certs="on"
    else
        client_certs="optional"
    fi
    cat /app/etc/template.identity |
        sed "s/##ALLOWED_HOSTS##/$APPLIANCE_DOMAIN/g;s/##VERIFY_CLIENT##/$client_certs/g" > /app/etc/server.identity
    systemctl reload-or-restart nginx
}
