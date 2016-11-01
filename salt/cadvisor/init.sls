include:
  - docker

/etc/systemd/system/cadvisor.service:
  file.managed:
    - source: salt://cadvisor/cadvisor.service

cadvisor:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/cadvisor.service
    - watch:
      - file: /etc/systemd/system/cadvisor.service
