# everything that should be absent but is not because of legacy leftover

{% set services_remove=[
  'watch_ecs_ca.path',
  'watch_ecs_ca.service',
  'update-appliance.service',
  ]
%}
{% set files_remove=[
  '/usr/local/sbin/generate-new-env.sh',
  '/usr/local/sbin/deploy_cert_as_root.sh',
  '/usr/local/sbin/unchanged_cert_as_root.sh',
  '/usr/local/share/appliance/update-appliance.sh',
  ]
%}

{% for f in services_remove %}
service_remove_{{ f }}:
  cmd.run:
    - name: systemctl disable {{ f }} || true
    - onlyif: test -e /etc/systemd/system/{{ f }}
  file.absent:
    - name: /etc/systemd/system/{{ f }}
{% endfor %}

{% for f in files_remove %}
file_remove_{{ f }}:
  file.absent:
    - name: {{ f }}
{% endfor %}
