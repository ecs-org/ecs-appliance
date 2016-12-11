include:
  - docker
  - cadvisor
  - .ssl
  - .nginx
  - .postfix
  - .stunnel
  - .postgresql
  - .backup
  - .legacy-removal

{% for i in ['appliance.include', 'prepare-env.sh', 'prepare-appliance.sh',
  'prepare-ecs.sh', 'update-appliance.sh'] %}
/usr/local/share/appliance/{{ i }}:
  file.managed:
    - source: salt://appliance/scripts/{{ i }}
    - mode: "0755"
    - makedirs: true
{% endfor %}

/app/etc/compose:
  file.recurse:
    - source: salt://appliance/ecs
    - keep_symlinks: true
    - makedirs: true

/app/etc/compose/service_urls.env:
  file.managed:
    - contents: |
        REDIS_URL=redis://ecs_redis_1:6379/0
        MEMCACHED_URL=memcached://ecs_memcached_1:11211
        SMTP_URL=smtp://{{ salt['pillar.get']('docker:ip') }}:25

/app/etc/compose/database_url.env:
  file.managed:
    - contents: |
        DATABASE_URL=postgres://app:invalid@{{ salt['pillar.get']('docker:ip') }}:5432/ecs
    - replace: false

{% for n in ['prepare-env.service', 'update-appliance.service',
  'prepare-appliance.service', 'prepare-ecs.service', 'appliance.service',
  'appliance-cleanup.service'] %}
install_{{ n }}:
  file.managed:
    - name: /etc/systemd/system/{{ n }}
    - source: salt://appliance/systemd/{{ n }}
    - watch_in:
      - cmd: systemd_reload
  cmd.wait:
    - name: systemctl enable {{ n }}
    - watch:
      - file: install_{{ n }}
{% endfor %}

/etc/systemd/system/appliance-failed@.service:
  file.managed:
    - source: salt://appliance/systemd/appliance-failed@.service
    - watch_in:
      - cmd: systemd_reload

/etc/systemd/system/watch-ecs-ca.service:
  file.managed:
    - source: salt://appliance/systemd/watch-ecs-ca.service

/etc/systemd/system/watch-ecs-ca.path:
  file.managed:
    - source: salt://appliance/systemd/watch-ecs-ca.path
    - watch_in:
      - cmd: systemd_reload
  cmd.wait:
    - name: systemctl enable watch-ecs-ca.path
    - watch:
      - file: /etc/systemd/system/watch-ecs-ca.path
      - file: /etc/systemd/system/watch-ecs-ca.service

systemd_reload:
  cmd.wait:
    - name: systemctl daemon-reload
    - order: last
