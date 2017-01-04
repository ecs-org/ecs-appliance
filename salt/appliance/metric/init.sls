include:
  - .cadvisor
{#
  - .pghero
  - .postgres_exporter
  - .node-exporter
  - .memcached-exporter
  - .prometheus
#}

# monitor postgres, memcached, (redis), (both nginx), uwsgi,
# cpu-load, memory, disk-i/o, disk-free, container

{% macro metric_install(name) %}
/etc/systemd/system/{{ name }}.service:
  file.managed:
    - source: salt://appliance/metric/{{ name }}.service
    - watch_in:
      - cmd: systemd_reload

service_{{ name }}:
  service.running:
    - name: {{ name }}
    - enable: true
    - require:
      - sls: docker
      - file: /etc/systemd/system/{{ name }}.service
    - watch:
      - file: /etc/systemd/system/{{ name }}.service

{% endmacro %}
