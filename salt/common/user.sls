{% from "ssh/lib.sls" import ssh_keys_update %}

application_user:
  group.present:
    - name: app
  user.present:
    - name: app
    - gid: app
    - home: /app
    - shell: /bin/bash
    - remove_groups: False
  file.directory:
    - name: /app/.ssh
    - user: app
    - group: app
    - dir_mode: 700
    - recurse:
      - user
      - group
      - mode
    - require:
      - user: application_user


{{ ssh_keys_update('app',
    salt['pillar.get']('ssh_authorized_keys', False),
    salt['pillar.get']('ssh_deprecated_keys', False)
    )
}}

{% for n in ['ecs', 'appliance'] %}
ensure_app_user_on_{{ n }}:
  file.directory:
    - name: /app/{{ n }}
    - user: app
    - group: app
    - recurse:
      - user
      - group
    - require:
      - user: application_user
{% endfor %}

{% for i in ".bash_logout", ".bashrc", ".profile" %}
application_skeleton_{{ i }}:
  file.copy:
    - name: /app/{{ i }}
    - source: /etc/skel/{{ i }}
    - user: app
    - group: app
    - unless: test /app/{{ i }} -nt /etc/skel/{{ i }}
    - require:
      - user: application_user
{% endfor %}
