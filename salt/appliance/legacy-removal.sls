# everything that should be absent but is not because of legacy leftover

{% set service_remove=[
  '/etc/systemd/system/watch_ecs_ca.path',
  '/etc/systemd/system/watch_ecs_ca.service',
  ]
%}
{% for f in service_remove %}
remove_{{ f }}:
  cmd.run:
    - name: systemctl stop {{ f }} || true
    - onlyif: test -e {{ f }}
  file.absent:
    - name: {{ f }}
{% endfor %}

{% set files_absent=[
  '/usr/local/sbin/generate-new-env.sh',
  '/usr/local/sbin/deploy_cert_as_root.sh',
  '/usr/local/sbin/unchanged_cert_as_root.sh',
  ]
%}
{% for f in files_absent %}
remove_{{ f }}:
  file.absent:
    - name: {{ f }}
{% endfor %}
