include:
  - common

/usr/local/share/appliance:
  file:
    - directory

/app/etc:
  file.directory:
    - user: root
    - group: root
    - require:
      - sls: common

{% for n in ['tags', 'flags', 'hooks'] %}
create_app_etc_{{ n }}:
  file.directory:
    - name: /app/etc/{{ n }}
    - user: root
    - group: root
    - require:
      - file: /app/etc
{% endfor %}
