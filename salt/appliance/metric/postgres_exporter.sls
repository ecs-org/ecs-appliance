include:
  - docker
  - systemd.reload

/etc/systemd/system/postgres_exporter.service:
  file.managed:
    - source: salt://appliance/metric/postgres_exporter.service
    - watch_in:
      - cmd: systemd_reload

postgres_exporter:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/postgres_exporter.service
    - watch:
      - file: /etc/systemd/system/postgres_exporter.service
