# everything that should be absent but is not because of legacy leftover

{% set service_remove=[
  '/etc/systemd/system/watch_ecs_ca.path',
  '/etc/systemd/system/watch_ecs_ca.service',
  ]
%}
{% for f in service_remove %}
remove_{{ f }}:
  cmd.run: systemctl stop {{ f }}
    - onlyif: test -e {{ f }}
  file.absent:
    - onlyif: test -e {{ f }}
{% endfor %}
