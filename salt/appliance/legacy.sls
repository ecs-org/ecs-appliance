# everything that should be absent but is not because of legacy
# everything that should have different user/group/permissions but is not because of legacy

{% set services_remove= [
  'watch_ecs_ca.path',
  'watch_ecs_ca.service',
  'update-appliance.service',
  ]
%}
{% set paths_remove= [
  '/usr/local/sbin/generate-new-env.sh',
  '/usr/local/sbin/deploy_cert_as_root.sh',
  '/usr/local/sbin/unchanged_cert_as_root.sh',
  '/usr/local/share/appliance/update-appliance.sh',
  '/usr/local/etc/appliance.include',
  '/usr/local/etc/env.include',
  '/usr/local/sbin/prepare-appliance.sh',
  '/usr/local/sbin/prepare-env.sh',
  '/usr/local/sbin/update-appliance.sh',
  '/usr/local/sbin/prepare-ecs.sh',
  '/usr/local/sbin/update-ecs.sh',
  '/etc/appliance',
  '/data/appliance',
  '/app/etc/rebuild_wanted_ecs'
  ]
%}
{% set path_user_group_dmode_fmode= [
  ('/app/etc/dehydrated/', 'app', 'app', '0755', '0664'),
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

{% for f in paths_remove %}
path_remove_{{ f }}:
  file.absent:
    - name: {{ f }}
{% endfor %}

{% for path,user,group,dmode,fmode in path_user_group_dmode_fmode %}
path_owner_set_{{ path }}:
  file.directory:
    - name: {{ path }}
    - user: {{ user }}
    - group: {{ group }}
    - dir_mode: {{ dmode }}
    - file_mode: {{ fmode }}
    - recurse:
      - user
      - group
      - mode
{% endfor %}
