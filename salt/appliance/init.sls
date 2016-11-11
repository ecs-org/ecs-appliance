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

/etc/appliance/ecs/service_urls.env:
  file.managed:
    - contents: |
        REDIS_URL=redis://ecs_redis_1:6379/0
        MEMCACHED_URL=memcached://ecs_memcached_1:11211
        SMTP_URL=smtp://{{ salt['pillar.get']('docker:ip') }}:25
        DATABASE_URL=postgres://app:invalidpassword@{{ salt['pillar.get']('docker:ip') }}:5432/ecs

appliance_service:
  file.managed:
    - name: /etc/systemd/system/appliance.service
    - source: salt://appliance/appliance.service
  cmd.wait:
    - name: systemctl daemon-reload
    - watch:
      - file: appliance_service
    - order: last
