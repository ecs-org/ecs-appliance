# everything that should be absent but is not because of legacy
# everything that should have different user/group/permissions but is not because of legacy

# Example: 'memcached-exporter.service',
{% set services_remove= [
  ]
%}
# Example: '/root/.gpg',
{% set paths_remove= [
  ]
%}
# Example: ('/app/etc/dehydrated/', 'app', 'app', '0755', '0664'),
{% set path_user_group_dmode_fmode= [
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
