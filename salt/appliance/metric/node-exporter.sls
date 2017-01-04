include:
  - docker
  - systemd.reload

/etc/systemd/system/node-exporter.service:
  file.managed:
    - source: salt://appliance/metric/node-exporter.service
    - watch_in:
      - cmd: systemd_reload

node-exporter:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/node-exporter.service
    - watch:
      - file: /etc/systemd/system/node-exporter.service
