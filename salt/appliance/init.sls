include:
  - docker
  - cadvisor
  - systemd.reload
  - .ssl
  - .nginx
  - .postfix
  - .stunnel
  - .postgresql
  - .backup
  - .legacy-removal

{% for i in ['appliance.include', 'prepare-env.sh', 'prepare-appliance.sh',
  'prepare-ecs.sh', 'appliance-update.sh'] %}
/usr/local/share/appliance/{{ i }}:
  file.managed:
    - source: salt://appliance/scripts/{{ i }}
    - mode: "0755"
    - makedirs: true
{% endfor %}

{% for n in ['compose', 'tags'] %}
create_app_etc_{{ n }}:
  file.directory:
    - name: /app/etc/{{ n }}
    - makedirs: true
    - user: app
    - group: app
{% endfor %}

/app/etc/ecs:
  file.recurse:
    - source: salt://appliance/ecs
    - keep_symlinks: true

/app/etc/ecs/service_urls.env:
  file.managed:
    - contents: |
        REDIS_URL=redis://ecs_redis_1:6379/0
        MEMCACHED_URL=memcached://ecs_memcached_1:11211
        SMTP_URL=smtp://{{ salt['pillar.get']('docker:ip') }}:25

/app/etc/ecs/database_url.env:
  file.managed:
    - contents: |
        DATABASE_URL=postgres://app:invalid@{{ salt['pillar.get']('docker:ip') }}:5432/ecs
    - replace: false

{% for n in ['prepare-env.service', 'prepare-appliance.service',
  'prepare-ecs.service', 'appliance.service',
  'appliance-cleanup.service', 'appliance-update.service',
  ] %}
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
    - watch_in:
      - cmd: systemd_reload

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
