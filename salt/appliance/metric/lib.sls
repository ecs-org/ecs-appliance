include:
  - systemd.reload
  - docker

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

{% if salt['pillar.get']('name', '') %}
  {{ metric_install(pillar.name) }}
{% endif %}
