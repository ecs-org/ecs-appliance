include:
  - systemd.reload

{% for n in [
  'prepare-env.service', 'prepare-appliance.service', 'prepare-ecs.service',
  'appliance-cleanup.service',
  'appliance-failed@.service', 'service-failed@.service',
  'watch-ecs-ca.service', 'watch-ecs-ca.path',
  'mail-to-sentry.service', 'mail-to-sentry.path',
  ] %}
install_{{ n }}:
  file.managed:
    - name: /etc/systemd/system/{{ n }}
    - source: salt://appliance/systemd/{{ n }}
    - watch_in:
      - cmd: systemd_reload
{% endfor %}

{% for n in ['watch-ecs-ca', 'mail-to-sentry',] %}
/etc/systemd/system/{{ n }}.path:
  cmd.wait:
    - name: systemctl enable {{ n }}.path
    - order: last
    - watch:
      - file: /etc/systemd/system/{{ n }}.path
      - file: /etc/systemd/system/{{ n }}.service
{% endfor %}

install_appliance.service:
  file.managed:
    - name: /etc/systemd/system/appliance.service
    - source: salt://appliance/systemd/appliance.service
    - watch_in:
      - cmd: systemd_reload
  cmd.wait:
    - name: systemctl enable appliance.service
    - order: last
    - watch:
      - file: install_appliance.service
