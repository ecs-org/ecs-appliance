nginx:
  pkg.installed:
    - pkgs:
      - nginx
      - ssl-cert
  service.running:
    - enable: true
    - require:
      - pkg: nginx
      - file: /etc/appliance/server.identity
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/appliance/server.identity

{% for a in ['app-template.html', 'snakeoil.identity', 'template.identity'] %}
/etc/appliance/{{ a }}:
  file.managed:
    - source: salt://appliance/nginx/{{ a }}
    - makedirs: true
{% endfor %}

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://appliance/nginx/nginx.conf

generate_snakeoil:
  cmd.run:
    - name: make-ssl-cert generate-default-snakeoil --force-overwrite
    - unless: test -f /etc/ssl/private/ssl-cert-snakeoil.key
    - require:
      - pkg: nginx

/etc/appliance/server.identity:
  file.symlink:
    - source: /etc/appliance/snakeoil.identity
    - require:
      - cmd: generate_snakeoil

/etc/appliance/server.cert.pem:
  file.symlink:
    - source: /etc/ssl/certs/ssl-cert-snakeoil.pem

/etc/appliance/server.key.pem:
  file.symlink:
    - source: /etc/ssl/private/ssl-cert-snakeoil.key

/etc/appliance/ca.cert.pem:
  file.symlink:
    - source: /app/ecs-ca/ca.cert.pem

/etc/appliance/crl.pem:
  file.symlink:
    - source: /app/ecs-ca/crl.pem
