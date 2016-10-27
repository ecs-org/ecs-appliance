
generate_snakeoil:
  pkg.installed:
    - name: ssl-cert
  cmd.run:
    - name: make-ssl-cert generate-default-snakeoil --force-overwrite
    - unless: test -f /etc/ssl/private/ssl-cert-snakeoil.key
    - require:
      - pkg: generate_snakeoil

/etc/appliance/server.cert.pem:
  file.symlink:
    - target: /etc/ssl/certs/ssl-cert-snakeoil.pem

/etc/appliance/server.key.pem:
  file.symlink:
    - target: /etc/ssl/private/ssl-cert-snakeoil.key

/etc/appliance/ca.cert.pem:
  file.symlink:
    - target: /app/ecs-ca/ca.cert.pem

/etc/appliance/crl.pem:
  file.symlink:
    - target: /app/ecs-ca/crl.pem
