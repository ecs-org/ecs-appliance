include:
  - docker
  - systemd.reload

{% for i in ['pghero-container.service', 'pghero-query-stats.service', 'pghero-query-stats.timer'] %}
/etc/systemd/system/{{ i }}:
  file.managed:
    - source: salt://appliance/metric/pghero/{{ i }}
    - watch_in:
      - cmd: systemd_reload
{% endfor %}

/usr/local/bin/recreate-pghero_query_stats:
  file.managed:
    - source: salt://appliance/metric/pghero/recreate-pghero_query_stats
    - mode: 0755

pghero-container:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/pghero-container.service
    - watch:
      - file: /etc/systemd/system/pghero-container.service

pghero-query-stats.timer:
  service.running:
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/pghero-query-stats.timer
    - watch:
      - file: /etc/systemd/system/pghero-query-stats.timer
      - file: /etc/systemd/system/pghero-query-stats.service
