# everything that should be absent but is not because of legacy leftover

{% set service_remove=[
  '/etc/systemd/system/watch_ecs_ca.path',
  '/etc/systemd/system/watch_ecs_ca.service',
  ]
%}
