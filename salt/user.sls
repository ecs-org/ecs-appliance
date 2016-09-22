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

{% for i in ".bash_logout", ".bashrc", ".profile" %}

application_skeleton_{{ i }}:
  file.copy:
    - name: /app/{{ i }}
    - source: /etc/skel/{{ i }}
    - user: app
    - group: app
    - require:
      - user: application_user

{% endfor %}

chown_app_app:
  cmd.run:
    - name: chown -R app:app /app
    - require:
      - user: application_user
