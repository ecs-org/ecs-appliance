# dehydrated is a letsencrypt shell client 
/usr/local/bin/dehydrated:
  file.managed:
    - source: salt://appliance/ssl/dehydrated
    - mode: "0755"

/usr/local/etc/dehydrated/config:
  file.managed:
    - contents: |
        BASEDIR="/etc/appliance/dehydrated"
        WELLKNOWN="/etc/appliance/dehydrated/acme-challenge"
    - makedirs: true

{% for i in ['acme-challenge', 'certs'] %}
/etc/appliance/dehydrated/{{ i }}:
  file.directory:
    - makedirs: true
{% endfor %}

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
