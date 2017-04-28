include:
  - appliance.directories

/app/etc/ecs:
  file.directory:
    - user: root
    - group: root
    - require:
      - sls: appliance.directories

{% for i in ['mocca', 'pdfas'] %}
/app/etc/ecs/{{ i }}:
  file.recurse:
    - source: salt://appliance/ecs/{{ i }}
{% endfor %}

/app/etc/ecs/docker-compose.yml:
  file.managed:
    - source: salt://appliance/ecs/docker-compose.yml
    - template: jinja

/app/etc/ecs/ecs:
  file.symlink:
    - target: /app/ecs
    - force: true

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
