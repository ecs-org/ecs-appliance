nginx:
  pkg.installed:
    - name: nginx
  service.running:
    - enable: true
    - require:
      - pkg: nginx
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

/etc/nginx/app/server.identity:
  file.symlink:
    - source: /etc/nginx/app/snakeoil.identity

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

/etc/nginx/app/snakeoil.cert.pem:

/etc/nginx/app/snakeoil.key.pem:
  
