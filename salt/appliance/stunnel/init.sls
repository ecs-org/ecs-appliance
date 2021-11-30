{% set def_route_device = salt['cmd.run_stdout'](
    'ip route list default | grep -E "^default via" | sed -r "s/.+ dev ([^ ]+).*/\\1/g"', python_shell=true) %}
{% set def_route_ip = salt['cmd.run_stdout'](
    'ip addr show '+ def_route_device+ ' | grep -E "^ +inet " | sed -r "s/^ +inet ([0-9.]+).+/\\1/g"', python_shell=true) %}

include:
  - appliance.directories
  - appliance.ssl
  - systemd.reload

/usr/local/share/appliance/prepare-stunnel.sh:
  file.managed:
    - source: salt://appliance/stunnel/prepare-stunnel.sh
    - require:
      - sls: appliance.directories

/app/etc/stunnel.conf:
  file.managed:
    - source: salt://appliance/stunnel/stunnel.conf
    - template: jinja
    - defaults:
        main_ip: {{ def_route_ip }}
    - require:
      - pkg: stunnel
      - sls: appliance.directories

/etc/systemd/system/stunnel.service:
  file.managed:
    - source: salt://appliance/stunnel/stunnel.service
    - watch_in:
      - cmd: systemd_reload
    - require:
      - pkg: stunnel

stunnel:
  pkg.installed:
    - name: stunnel4
  cmd.run:
    - name: setcap CAP_NET_BIND_SERVICE=+eip /usr/bin/stunnel4
    - unless: setcap -v CAP_NET_BIND_SERVICE=+eip /usr/bin/stunnel4
    - require:
      - pkg: stunnel
  service.running:
    - enable: true
    - require:
      - cmd: stunnel
      - sls: appliance.ssl
      - file: /app/etc/stunnel.conf
      - file: /etc/systemd/system/stunnel.service
    - watch:
      - file: /app/etc/stunnel.conf
      - file: /app/etc/server.cert.dhparam.pem
