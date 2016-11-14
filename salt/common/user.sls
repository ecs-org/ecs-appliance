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
    - mode: 700
    - require:
      - user: application_user

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
