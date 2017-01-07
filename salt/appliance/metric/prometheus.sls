include:
  - systemd.reload
  - docker

{% macro metric_install(name, start=false) %}
/etc/systemd/system/{{ name }}.service:
  file.managed:
    - source: salt://appliance/metric/{{ name }}.service
    - template: jinja
    - watch_in:
      - cmd: systemd_reload

service_{{ name }}:
  {% if start %}
  service.running:
    - enable: true
  {% else %}
  service.enabled:
  {% endif %}
    - name: {{ name }}
    - require:
      - sls: docker
      - file: /etc/systemd/system/{{ name }}.service
    - watch:
      - file: /etc/systemd/system/{{ name }}.service

{% endmacro %}


{% if salt['pillar.get']('name', '') %}
{{ metric_install(pillar.name) }}

{% else %}

/app/etc/prometheus.yml:
  file.managed:
    - source: salt://appliance/metric/prometheus.yml
    - template: jinja

/app/etc/alertmanager.yml:
  file.managed:
    - source: salt://appliance/metric/alertmanager.yml
    - template: jinja

/app/etc/alert.rules:
  file.managed:
    - source: salt://appliance/metric/alert.rules

{{ metric_install('cadvisor') }}
{{ metric_install('node-exporter') }}
{{ metric_install('postgres_exporter') }}
{{ metric_install('process-exporter') }}
{{ metric_install('alertmanager') }}
{{ metric_install('prometheus') }}
{{ metric_install('grafana') }}

{% endif %}
