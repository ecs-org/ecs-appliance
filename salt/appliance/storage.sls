{% from 'storage/lib.sls' import storage_setup with context %}


{% if (not salt['pillar.get']("appliance:storage:ignore:volatile",false) and
       not salt['files.exists']('/dev/disk/by-label/ecs-volatile')) or
      (not salt['pillar.get']("appliance:storage:ignore:data",false) and
       not salt['files.exists']('/dev/disk/by-label/ecs-data')) ) %}

  {{ storage_setup(salt['pillar.get']("appliance:storage:setup")) }}
{% endif %}


{% load_yaml as volatile_prepare %}
  {% if salt['pillar.get']("appliance:storage:ignore:volatile",false) %}
mount:
  /volatile:
    device: /dev/disk/by-label/ecs-volatile
    mkmnt: true
    fstype: ext4
  {% endif %}

directories:
  /volatile:
    names:
      - docker
      - ecs-log
      - ecs-cache
      - container/redis
      - container/postfix
      - container/elasticsearch
      # FIXME tmp and var/tmp have different dir_mode
      # - tmp
      # - var/tmp
    options:
      - group: app
      - user: app
      - dir_mode: 775
      - file_mode: 664
{% if salt['pillar.get']("appliance:storage:ignore:volatile",false) %}
    onlyif: mountpoint -q /volatile
{% endif %}
relocate:
  /var/lib/docker:
    destination: /volatile/docker
    copy_content: False
    watch_in: "service: docker"
  /app/ecs-log:
    destination: /volatile/ecs-log
  /app/ecs-cache:
    destination: /volatile/ecs-cache
  /app/container/redis:
    destination: /volatile/container/redis
  /app/container/postfix:
    destination: /volatile/container/postfix
  # FIXME tmp and var/tmp have different dir_mode
  # /tmp:
  #   destination: /volatile/tmp
  # /var/tmp:
  #  destination: /volatile/var/tmp
{% endload %}
{{ storage_setup(volatile_prepare) }}


{% load_yaml as data_prepare %}
  {% if salt['pillar.get']("appliance:storage:ignore:data",false) %}
mount:
  /data:
    device: /dev/disk/by-label/ecs-data
    mkmnt: true
    fstype: ext4
  {% endif %}
directories:
  /data:
    names:
      - ecs-storage-vault
      - ecs-ca
      - ecs-letsencrypt
      - container/ecs-postgres
      - ecs-pgdump
    options:
      - group: app
      - user: app
      - dir_mode: 775
      - file_mode: 664
  {% if salt['pillar.get']("appliance:storage:ignore:data",false) %}
    onlyif: mountpoint -q /data
  {% endif %}
{% endload %}
{{ storage_setup(data_prepare) }}
