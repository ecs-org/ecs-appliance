include:
  - appliance.ssl

/etc/appliance/stunnel.conf:
  file.managed:
    - source: salt://appliance/stunnel/stunnel.conf
    - makedirs: true
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
      - file: /etc/appliance/server.key.pem

# fixme: dhparam is not ready on build time, does stunnel create dhparam on start ?
