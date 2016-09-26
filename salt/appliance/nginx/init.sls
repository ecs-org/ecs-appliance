nginx:
  pkg.installed:
    - pkgs:
      - nginx
      - ssl-cert
  file.directory:
    - name: /etc/nginx/app
    - require:
      - pkg: nginx
  service.running:
    - enable: true
    - require:
      - file: nginx
      - file: /etc/nginx/app/server.identity
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/app/server.identity

{% for a in ['app-template.html', 'snakeoil.identity', 'template.identity'] %}
/etc/nginx/app/{{ a }}:
  file.managed:
    - source: salt://appliance/nginx/{{ a }}
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

/etc/nginx/app/server.identity:
  file.symlink:
    - source: /etc/nginx/app/snakeoil.identity
    - require:
      - cmd: generate_snakeoil

/etc/nginx/app/server.cert.pem:
  file.symlink:
    - source: /data/ecs-letsencrypt/fullchain.pem

/etc/nginx/app/server.key.pem:
  file.symlink:
    - source: /data/ecs-letsencrypt/privkey.pem

/etc/nginx/app/ca.cert.pem:
  file.symlink:
    - source: /data/ecs-ca/ca.cert.pem

/etc/nginx/app/crl.pem:
  file.symlink:
    - source: /data/ecs-ca/crl.pem
