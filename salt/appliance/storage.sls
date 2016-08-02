{% from 'storage/lib.sls' import storage_setup with context %}


{% if not salt['files.exists']('/dev/disk/by-label/ecs-volatile') %}
  {% load_yaml as custom_storage %}
format:
  /dev/{{ pillar.get('ecs:storage:volatile') }}:
    fstype: ext4
    opts: "-L ecs-volatile"
mount:
  /volatile:
    device: /dev/disk/by-label/ecs-volatile
    mkmnt: true
    fstype: ext4
directories:
  /volatile:
    names:
      - tmp
      - var/tmp
      - docker
      - ecs-log
      - ecs-cache
      - container/elasticsearch
      - container/redis
      - container/postfix
    options:
      - group: app
      - user: app
      - dir_mode: 775
      - file_mode: 664
    onlyif: mountpoint -q /volatile
relocate:
  /var/lib/docker:
    destination: /volatile/docker
    copy_content: False
    watch_in: "service: docker"
  /tmp:
    destination: /volatile/tmp
  /var/tmp:
    destination: /volatile/var/tmp
  /app/ecs-log:
    destination: /volatile/ecs-log
  /app/ecs-cache:
    destination: /volatile/ecs-cache
  /container/redis:
    destination: /volatile/container/redis
  /container/postfix:
    destination: /volatile/container/postfix
  {% endload %}

  {{ storage_setup(custom_storage) }}
{% endif %}


{% if not salt['files.exists']('/dev/disk/by-label/ecs-data') %}
  {% load_yaml as custom_storage %}
    {% if pillar.get('ecs:storage:permanent:snapshot_type', 'unknown') == 'lvm' %}
lvm:
  pv:
    - /dev/{{ pillar.get('ecs:storage:permanent:device') }}
  vg:
    vgdata:
      devices:
        - /dev/{{ pillar.get('ecs:storage:permanent:device') }}
  lv:
    lv_ecs:
      vgname: vgdata
      size: "80%"
format:
  /dev/mapper/vgdata-lvdata:
    fstype: ext4
    opts: "-L ecs-data"

    {% else %}
format:
  /dev/{{ pillar.get('ecs:storage:permanent:device') }}:
    fstype: ext4
    opts: "-L ecs-data"
    {% endif %}

mount:
  /data:
    device: /dev/disk/by-label/ecs-data
    mkmnt: true
    fstype: ext4
directories:
  /data:
    names:
      - ecs-storage-vault
      - container/ecs-postgres
      - ecs-pgdump
    options:
      - group: app
      - user: app
      - dir_mode: 775
      - file_mode: 664
    onlyif: mountpoint -q /data

  {% endload %}
  {{ storage_setup(custom_storage) }}
{% endif %}
