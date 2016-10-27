include:
  - appliance.ssl

stunnel:
  pkg.installed:
    - name: stunnel4
  service.running:
    - enable: true
    - require:
      - pkg: stunnel
      - sls: appliance.ssl
      - file: /etc/stunnel/stunnel.conf
    - watch:
      - file: /etc/stunnel/stunnel.conf
      - file: /etc/appliance/server.cert.dhparam.pem
      - file: /etc/appliance/server.key.pem

/etc/stunnel/stunnel.conf:
  file.managed:
    - source: salt://appliance/stunnel/stunnel.conf
    - makedirs: true
    - require:
      - pkg: stunnel
