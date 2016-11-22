include:
  - docker
  - cadvisor
  - .ssl
  - .nginx
  - .postfix
  - .stunnel
  - .postgresql
  - .backup


/usr/local/etc/appliance.include:
  file.managed:
    - source: salt://appliance/scripts/appliance.include

{% for i in ['prepare-env.sh', 'prepare-appliance.sh',
  'prepare-ecs.sh', 'update-appliance.sh', 'update-ecs.sh'] %}
/usr/local/sbin/{{ i }}:
  file.managed:
    - source: salt://appliance/scripts/{{ i }}
    - mode: "0755"
{% endfor %}

/etc/appliance/ecs:
  file.recurse:
    - source: salt://appliance/ecs
    - keep_symlinks: true

/etc/appliance/ecs/service_urls.env:
  file.managed:
    - contents: |
        REDIS_URL=redis://ecs_redis_1:6379/0
        MEMCACHED_URL=memcached://ecs_memcached_1:11211
        SMTP_URL=smtp://{{ salt['pillar.get']('docker:ip') }}:25

/etc/appliance/ecs/database_url.env:
  file.managed:
    - contents: |
        DATABASE_URL=postgres://app:invalid@{{ salt['pillar.get']('docker:ip') }}:5432/ecs
    - replace: false

{% for n in ['prepare-env.service', 'prepare-appliance.service', 'prepare-ecs.service',
  'appliance.service', 'appliance-cleanup.service', 'appliance-failed@.service'] %}
install_{{ n }}:
  file.managed:
    - name: /etc/systemd/system/{{ n }}
    - source: salt://appliance/systemd/{{ n }}
  cmd.wait:
    - name: systemctl enable {{ n }}
    - watch:
      - file: install_{{ n }}
{% endfor %}
