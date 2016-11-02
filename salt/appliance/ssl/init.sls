include:
  - common.user

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
        HOOK="/etc/appliance/dehydrated-hook.sh"
    - makedirs: true

{% for i in ['acme-challenge', 'certs'] %}
/etc/appliance/dehydrated/{{ i }}:
  file.directory:
    - makedirs: true
    - user: app
    - require:
      - sls: common.user
{% endfor %}

/etc/appliance/dehydrated-hook.sh:
  file.managed:
    - mode: "0755"
    - source: salt://appliance/ssl/dehydrated-hook.sh

{% for i in ['deploy_cert_as_root.sh', 'unchanged_cert_as_root.sh'] %}
/usr/local/sbin/{{ i }}:
  file.managed:
    - mode: "0755"
    - source: salt://appliance/ssl/{{ i }}
{% endfor %}

/etc/sudoers.d/newcert_auth:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        app ALL=(ALL) NOPASSWD: /usr/local/sbin/deploy_cert_as_root.sh
        app ALL=(ALL) NOPASSWD: /usr/local/sbin/unchanged_cert_as_root.sh

generate_snakeoil:
  pkg.installed:
    - name: ssl-cert
  cmd.run:
    - name: make-ssl-cert generate-default-snakeoil --force-overwrite
    - unless: test -f /etc/ssl/private/ssl-cert-snakeoil.key
    - require:
      - pkg: generate_snakeoil

/etc/appliance/ssl-cert-snakeoil.key:
  file.copy:
    - source: /etc/ssl/private/ssl-cert-snakeoil.key
    - mode: "0644"
    - require:
      - cmd: generate_snakeoil

/etc/appliance/ssl-cert-snakeoil.pem:
  file.copy:
    - source: /etc/ssl/certs/ssl-cert-snakeoil.pem
    - mode: "0644"
    - require:
      - cmd: generate_snakeoil

/etc/appliance/server.key.pem:
  file.symlink:
    - target: /etc/appliance/ssl-cert-snakeoil.key

/etc/appliance/server.cert.pem:
  file.symlink:
    - target: /etc/appliance/ssl-cert-snakeoil.pem

/etc/appliance/server.cert.dhparam.pem:
  file.symlink:
    - target: /etc/appliance/ssl-cert-snakeoil.pem

/etc/appliance/ca.cert.pem:
  file.symlink:
    - target: /app/ecs-ca/ca.cert.pem

/etc/appliance/crl.pem:
  file.symlink:
    - target: /app/ecs-ca/crl.pem
