postfix:
  pkg.installed:
    - pkgs:
      - postfix

/etc/mailname:
  file.managed:
    - contents: |
        hostname



/etc/postfix/main.cf:
  replace:
    - pattern: "^smtpd_tls_cert_file[ \t]*=(.+)$"
    - repl: smtpd_tls_cert_file=/etc/appliance/server.cert.pem

    - pattern: "^smtpd_tls_key_file[ \t]*=(.+)$"
    - repl: smtpd_tls_key_file=/etc/appliance/server.key.pem

    myhostname
