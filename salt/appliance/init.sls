include:
  - docker
  - .dehydrated
  - .nginx
  - .backup
  # - .postgresql
  # - .postfix

{% for i in ['prepare-appliance.sh', 'prepare-ecs.sh', 'update-appliance.sh', 'update-ecs.sh'] %}
/usr/local/sbin/{{ i }}:
  file.managed:
    - source: salt://appliance/{{ i }}
    - mode: "0755"
{% endfor %}

/usr/local/etc/appliance.include:
  file.managed:
    - source: salt://appliance/appliance.include

/etc/systemd/system/appliance.service:
  file.managed:
    - source: salt://appliance/appliance.service

/etc/appliance/compose:
  file.recurse:
    - source: salt://appliance/compose
    - keep_symlinks: true
