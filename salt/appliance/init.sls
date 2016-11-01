include:
  - docker
  - cadvisor
  - .ssl
  - .nginx
  - .postfix
  - .stunnel
  - .postgresql
  - .backup

{% for i in ['prepare-appliance.sh', 'prepare-ecs.sh', 'update-appliance.sh', 'update-ecs.sh'] %}
/usr/local/sbin/{{ i }}:
  file.managed:
    - source: salt://appliance/scripts/{{ i }}
    - mode: "0755"
{% endfor %}

/usr/local/etc/appliance.include:
  file.managed:
    - source: salt://appliance/scripts/appliance.include

/etc/appliance/ecs:
  file.recurse:
    - source: salt://appliance/ecs
    - keep_symlinks: true

appliance_service:
  file.managed:
    - name: /etc/systemd/system/appliance.service
    - source: salt://appliance/appliance.service
  cmd.wait:
    - name: systemctl daemon-reload
    - watch:
      - file: appliance_service
    - order: last
