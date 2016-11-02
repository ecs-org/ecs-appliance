include:
  - appliance.ssl

/etc/appliance/stunnel.conf:
  file.managed:
    - source: salt://appliance/stunnel/stunnel.conf
    - template: jinja
    - makedirs: true
    - defaults:
        main_ip: {{ salt['network.get_route'](salt['network.default_route']('inet')[0].gateway).source }}
    - require:
      - pkg: stunnel

/etc/systemd/system/stunnel.service:
  file.managed:
    - source: salt://appliance/stunnel/stunnel.service
    - require:
      - pkg: stunnel

stunnel:
  pkg.installed:
    - name: stunnel4
  service.running:
    - enable: true
    - require:
      - sls: appliance.ssl
      - file: /etc/appliance/stunnel.conf
      - file: /etc/systemd/system/stunnel.service
    - watch:
      - file: /etc/appliance/stunnel.conf
      - file: /etc/appliance/server.cert.dhparam.pem

# fixme: dhparam is not ready on build time, does stunnel create dhparam on start ?
