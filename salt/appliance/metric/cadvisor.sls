include:
  - docker
  - systemd.reload

/etc/systemd/system/cadvisor.service:
  file.managed:
    - source: salt://appliance/monitor/cadvisor.service
    - watch_in:
      - cmd: systemd_reload

cadvisor:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/cadvisor.service
    - watch:
      - file: /etc/systemd/system/cadvisor.service
