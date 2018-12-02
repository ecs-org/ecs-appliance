# #### custom legacy remove

# services that need to be disabled
# Example: 'appliance-cleanup.service',
{% set services_disable= [
'appliance-cleanup.service',
'prepare-appliance.service',
'prepare-ecs.service',
'prepare-env.service',
  ]
%}
# services that need to be disabled, stopped and removed
# Example: 'memcached-exporter.service',
{% set services_remove= [
'pghero-query-stats.service',
'pghero-query-stats.timer',
  ]
%}
# paths that need to be removed
# Example: '/root/.gpg',
{% set paths_remove= [
'/usr/local/bin/recreate-pghero_query_stats',
'/app/ecs-homepage',
'/app/prometheus/metric_import',
'/app/etc/flags/rebuild_wanted_appliance',
'/app/etc/flags/rebuild_wanted_ecs',
'/etc/sudoers.d/90-app-sudo',
'/etc/systemd/system/default.target.wants/appliance-backup.service',
  ]
%}
# paths that should have different user/group/permissions
# Example: ('/app/etc/dehydrated/', 'app', 'app', '0755', '0664'),
{% set path_user_group_dmode_fmode= [
  ]
%}


# #### Functions

{% for f in services_disable %}
service_disable_{{ f }}:
  cmd.run:
    - name: systemctl disable {{ f }} || true
    - onlyif: systemctl is-enabled {{ f }}
{% endfor %}

{% for f in services_remove %}
service_disable_{{ f }}:
  cmd.run:
    - name: systemctl disable {{ f }} || true
    - onlyif: systemctl is-enabled {{ f }}
service_stop_{{ f }}:
  cmd.run:
    - name: systemctl stop {{ f }} || true
    - onlyif: systemctl is-active {{ f }}
service_remove_{{ f }}:
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
