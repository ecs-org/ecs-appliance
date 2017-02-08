prepare_stunnel () {
    sed -ri.bak  's/(accept[ \t]*=[ \t]*)([^:]+)/\1'"$(default_route_interface_ip)"'/g' /app/etc/stunnel.conf
    if ! diff -q /app/etc/stunnel.conf /app/etc/stunnel.conf.bak; then
        echo "stunnel configuration changed, new accept ip: $(default_route_interface_ip)"
    fi
    systemctl restart stunnel
}
