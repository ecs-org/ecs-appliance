include:
  - appliance.ssl

nginx:
  pkg.installed:
    - pkgs:
      - nginx
      - nginx-extras
  service.running:
    - enable: true
    - require:
      - pkg: nginx
      - sls: appliance.ssl
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/prometheus.lua
      - file: /app/etc/server.identity
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/prometheus.lua
      - file: /app/etc/server.identity

/usr/local/share/appliance/prepare-nginx.sh:
  file.managed:
    - source: salt://appliance/nginx/prepare-nginx.sh
    - makedirs: true

{% for a in ['app-template.html', 'snakeoil.identity', 'template.identity'] %}
/app/etc/{{ a }}:
  file.managed:
    - source: salt://appliance/nginx/{{ a }}
    - makedirs: true
{% endfor %}

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://appliance/nginx/nginx.conf
    - template: jinja

/etc/nginx/prometheus.lua:
  file.managed:
    - source: salt://appliance/nginx/prometheus.lua

/app/etc/server.identity:
  file.copy:
    - source: /app/etc/snakeoil.identity
    - replace: false
    - require:
      - file: /app/etc/snakeoil/ssl-cert-snakeoil.key
      - file: /app/etc/snakeoil/ssl-cert-snakeoil.pem
      - file: /app/etc/snakeoil.identity

/var/www/html/503.html:
  file.managed:
    - source: /app/etc/app-template.html
    - template: jinja
    - defaults:
        title: "System Information"
        text: "uninitialized"
    - replace: false
    - require:
      - file: /app/etc/app-template.html
