include:
  - docker
  - systemd.reload

{% for i in ['pghero-container.service',] %}
# XXX disabled, needs a lot of space: 'pghero-query-stats.service', 'pghero-query-stats.timer'
/etc/systemd/system/{{ i }}:
  file.managed:
    - source: salt://appliance/metric/pghero/{{ i }}
    - watch_in:
      - cmd: systemd_reload
{% endfor %}

{% for i in ['recreate-pghero_query_stats', 'remove-pghero_query_stats'] %}
/usr/local/share/appliance/{{ i }}:
  file.managed:
    - source: salt://appliance/metric/pghero/{{ i }}
    - mode: 0755
{% endfor %}

pghero-container:
  service.enabled:
    - require:
      - sls: docker
      - file: /etc/systemd/system/pghero-container.service

{#
# XXX disabled, needs a lot of space
pghero-query-stats.timer:
  service.enabled:
    - require:
      - sls: docker
      - file: /etc/systemd/system/pghero-query-stats.timer
      - file: /etc/systemd/system/pghero-query-stats.service

#}
