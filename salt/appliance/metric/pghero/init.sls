include:
  - docker
  - systemd.reload

/etc/systemd/system/pghero-container.service:
  file.managed:
    - source: salt://appliance/pghero-container.service
    - watch_in:
      - cmd: systemd_reload

pghero-container:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/pghero-container.service
    - watch:
      - file: /etc/systemd/system/pghero-container.service
