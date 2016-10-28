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

  # Both
  smtp_tls_cert_file=/etc/appliance/server.cert.pem
  smtp_tls_key_file=/etc/appliance/server.key.pem
  smtp_use_tls=yes

  # Incoming
  smtpd_tls_dh1024_param_file = /etc/appliance/dhparam.pem
  # is missleading name, takes >1024 dhparam
  smtpd_tls_eecdh_grade = strong #enable ECDH
  smtpd_tls_security_level=may
  smtpd_tls_protocols=!SSLv2,!SSLv3   # smtpd_tls_security_level=may
  smtpd_tls_ciphers = medium          # smtpd_tls_security_level=may
  smtpd_tls_mandatory_protocols=!SSLv2,!SSLv3
  smtpd_tls_mandatory_ciphers = high
  smtpd_tls_mandatory_exclude_ciphers = aNULL, MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL
  smtpd_tls_loglevel = 1 #enable TLS logging to see the ciphers for inbound connections

  # Outgoing
  #enforce the server cipher preference
  tls_preempt_cipherlist = yes
  smtp_tls_security_level = may
  smtp_tls_protocols = !SSLv2,!SSLv3  # smtpd_tls_security_level=may
  smtp_tls_ciphers = medium           # smtpd_tls_security_level=may
  smtp_tls_mandatory_protocols = !SSLv2,!SSLv3
  smtp_tls_mandatory_ciphers = high
  smtp_tls_mandatory_exclude_ciphers = aNULL, MD5, DES, ADH, RC4, PSD, SRP, 3DES, eNULL
  smtp_tls_loglevel = 1 #enable TLS logging to see the ciphers for outbound connections
