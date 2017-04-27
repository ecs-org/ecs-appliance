include:
  - common

{% for n in ['tags', 'flags'] %}
create_app_etc_{{ n }}:
  file.directory:
    - name: /app/etc/{{ n }}
    - makedirs: true
    - user: app
    - group: app
    - require:
      - sls: common

{% endfor %}
