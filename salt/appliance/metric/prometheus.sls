include:
  - systemd.reload
  - docker

{% macro metric_service_install(name) %}
/etc/systemd/system/{{ name }}.service:
  file.managed:
    - source: salt://appliance/metric/{{ name }}.service
    - template: jinja
    - watch_in:
      - cmd: systemd_reload

metric_service_{{ name }}:
  service.enabled:
    - name: {{ name }}
    - require:
      - sls: docker
      - file: /etc/systemd/system/{{ name }}.service
  # restarts service if changed and already running
  cmd.wait:
    - name: systemctl try-restart {{ name }}.service
    - watch:
      - file: /etc/systemd/system/{{ name }}.service

{% endmacro %}


{% macro metric_timer_install(name) %}
/etc/systemd/system/{{ name }}.timer:
  file.managed:
    - source: salt://appliance/metric/{{ name }}.timer
    - template: jinja
    - watch_in:
      - cmd: systemd_reload

/etc/systemd/system/{{ name }}.service:
  file.managed:
    - source: salt://appliance/metric/{{ name }}.service
    - template: jinja
    - watch_in:
      - cmd: systemd_reload

metric_timer_{{ name }}:
  service.enabled:
    - name: {{ name }}.timer
    - require:
      - file: /etc/systemd/system/{{ name }}.timer
      - file: /etc/systemd/system/{{ name }}.service
  # resets timer if changed and already running, but after systemd reload
  cmd.wait:
    - name: systemctl reenable --now {{ name }}.timer
    - watch:
      - file: /etc/systemd/system/{{ name }}.timer
    - require:
      - cmd: systemd_reload

{% endmacro %}


{% if salt['pillar.get']('name', '') %}
{{ metric_service_install(pillar.name) }}

{% else %}

/app/etc/metric_import:
  file.directory:
    - makedirs: true
    - user: 1000
    - group: 1000

/app/etc/prometheus-rules.d:
  file.directory:
    - makedirs: true

/app/etc/alertmanager-template.d:
  file.directory:
    - makedirs: true

/app/etc/prometheus.yml:
  file.managed:
    - source: salt://appliance/metric/prometheus.yml
    - template: jinja
    - watch_in:
      - cmd: metric_service_prometheus

/app/etc/alertmanager.yml:
  file.managed:
    - source: salt://appliance/metric/alertmanager.yml
    - template: jinja
    - watch_in:
      - cmd: metric_service_alertmanager
      - cmd: metric_service_prometheus

{% for i in ["alert.rules.yml", "hardware-alert.rules.yml"] %}
/app/etc/prometheus-rules.d/{{ i }}:
  file.managed:
    - source: salt://appliance/metric/{{ i }}
    - watch_in:
      - cmd: metric_service_alertmanager
      - cmd: metric_service_prometheus
{% endfor %}

/app/etc/alertmanager-template.d/email-simple.tmpl:
  file.managed:
    - source: salt://appliance/metric/email-simple.tmpl
    - watch_in:
      - cmd: metric_service_alertmanager

{% for n in ['smartmon-storage-metric.sh', 'nvme-storage-metric.sh'] %}
/usr/local/sbin/{{ n }}:
  file.managed:
    - source: salt://appliance/metric/{{ n }}
    - mode: "0755"
{% endfor %}

{{ metric_service_install('cadvisor') }}
{{ metric_service_install('node-exporter') }}
{{ metric_service_install('postgres_exporter') }}
{{ metric_service_install('process-exporter') }}
{{ metric_service_install('alertmanager') }}
{{ metric_timer_install('storage-metric-textfile') }}
{{ metric_service_install('prometheus') }}
{{ metric_service_install('grafana') }}

{% endif %}
