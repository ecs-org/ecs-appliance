{% from 'storage/lib.sls' import storage_setup with context %}

{% if (not salt['pillar.get']("appliance:storage:ignore:volatile", false) and
       not salt['file.file_exists']('/dev/disk/by-label/ecs-volatile')) or
      (not salt['pillar.get']("appliance:storage:ignore:data", false) and
       not salt['file.file_exists']('/dev/disk/by-label/ecs-data')) %}

  {{ storage_setup(salt['pillar.get']("appliance:storage:setup", {})) }}
{% endif %}


{% load_yaml as volatile_prepare %}
  {% if not salt['pillar.get']("appliance:storage:ignore:volatile",false) %}
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
      - ecs-backup-test
      - ecs-cache
      - redis
      # FIXME tmp and var/tmp have different dir_mode
      # - tmp
      # - var/tmp
    options:
      - group: app
      - user: app
      - dir_mode: 775
      - file_mode: 664
{% if not salt['pillar.get']("appliance:storage:ignore:volatile",false) %}
    onlyif: mountpoint -q /volatile
{% endif %}
relocate:
  /var/lib/docker:
    destination: /volatile
    exec_before: systemctl stop cadvisor; docker kill $(docker ps -q); systemctl stop docker
    exec_after: systemctl start docker; systemctl start cadvisor
  /app/ecs-cache:
    destination: /volatile
  # TODO tmp and var/tmp have different dir_mode
  # /tmp:
  #   destination: /volatile/tmp
  # /var/tmp:
  #  destination: /volatile/var/tmp
{% endload %}
{{ storage_setup(volatile_prepare) }}


{% load_yaml as data_prepare %}
  {% if not salt['pillar.get']("appliance:storage:ignore:data",false) %}
mount:
  /data:
    device: /dev/disk/by-label/ecs-data
    mkmnt: true
    fstype: ext4
  {% endif %}
directories:
  /data:
    names:
      - appliance
      - ecs-ca
      - ecs-pgdump
      - ecs-storage-vault
      - postgresql
    options:
      - group: app
      - user: app
      - dir_mode: 775
      - file_mode: 664
  {% if not salt['pillar.get']("appliance:storage:ignore:data",false) %}
    onlyif: mountpoint -q /data
  {% endif %}
relocate:
  /etc/appliance:
    destination: /data
  /app/ecs-ca:
    destination: /data
  /app/ecs-storage-vault:
    destination: /data
  /var/lib/postgresql:
    destination: /data
    exec_before: systemctl stop postgresql
    exec_after: systemctl start postgresql
{% endload %}
{{ storage_setup(data_prepare) }}
