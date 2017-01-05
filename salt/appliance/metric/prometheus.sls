include:
  - systemd.reload
  - docker

# monitor docker, postgres, uwsgi, memcached, (redis), (both nginx),
# cpu-load, memory, disk-i/o, disk-free, container
# uwsgi prometheus metric is exported from ecs.web container to localhost:1717 in docker-compose.yml

{% macro metric_install(name) %}
/etc/systemd/system/{{ name }}.service:
  file.managed:
    - source: salt://appliance/metric/{{ name }}.service
    - template: jinja
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


{% if salt['pillar.get']('name', '') %}

{{ metric_install(pillar.name) }}

{% else %}

{{ metric_install('cadvisor') }}
{{ metric_install('node-exporter') }}
{{ metric_install('postgres_exporter') }}
{{ metric_install('memcached_exporter') }}
{{ metric_install('alertmanager') }}
{{ metric_install('prometheus') }}
{{ metric_install('grafana') }}

  {% for i in 'prometheus.yml', 'alertmanager.yml', 'alert.rules' %}
/app/etc/{{ i }}:
  file.managed:
    - source: salt://appliance/metric/{{ i }}
    - template: jinja
  {% endfor %}

{% endif %}
