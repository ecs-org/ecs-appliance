stunnel:
  pkg.installed:
    - name: stunnel4
  service.running:
    - enable: true
    - require:
      - pkg: stunnel
      - file: /etc/appliance/server.identity
    - watch:
      - file: /etc/nginx/nginx.conf
      - file: /etc/appliance/server.identity
