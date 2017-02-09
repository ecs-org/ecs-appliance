include:
  - docker
  - systemd.reload
  - .extra
  - .ssl
  - .nginx
  - .postfix
  - .stunnel
  - .postgresql
  - .storage
  - .backup
  - .metric
  - .legacy

{% for i in ['appliance.include', 'prepare-env.sh', 'prepare-appliance.sh',
  'prepare-ecs.sh', 'appliance-update.sh'] %}
/usr/local/share/appliance/{{ i }}:
  file.managed:
    - source: salt://appliance/scripts/{{ i }}
    - mode: "0755"
    - makedirs: true
{% endfor %}

{% for n in ['create-client-certificate.sh', 'create-internal-user.sh'] %}
/usr/local/sbin/{{ n }}:
  file.managed:
    - source: salt://appliance/scripts/{{ n }}
    - mode: "0755"
{% endfor %}

{% for n in ['ecs', 'tags', 'flags'] %}
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
    - template: jinja

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

{% for n in ['appliance-failed@.service', 'service-failed@.service',
  'watch-ecs-ca.service', 'watch-ecs-ca.path',
  'mail-to-sentry.service', 'mail-to-sentry.path',
  ] %}
install_{{ n }}:
  file.managed:
    - name: /etc/systemd/system/{{ n }}
    - source: salt://appliance/systemd/{{ n }}
    - watch_in:
      - cmd: systemd_reload
{% endfor %}


{% for n in ['watch-ecs-ca', 'mail-to-sentry',] %}
/etc/systemd/system/{{ n }}.path:
  cmd.wait:
    - name: systemctl enable {{ n }}.path
    - watch:
      - file: /etc/systemd/system/{{ n }}.path
      - file: /etc/systemd/system/{{ n }}.service
{% endfor %}
