{% from 'storage/lib.sls' import storage_setup with context %}


{% if we are sure that we want to wipe the disk, and which disks %}

  {% if we have only one disk available %}

    {% load_yaml as custom_storage %}
  parted:
    /dev/vda:
      type: mbr
      parts:
        - name root
          start: 1024kiB
          end: "100%"
          flags:
            - boot
      format:
        /dev/vda1:
          fstype: ext4
          opts: "-L ecs-root"
    {% endload %}

  {% elif we have two disks available %}

    {% load_yaml as custom_storage %}
  parted:
      {% for a in ["/dev/vdb", "/dev/vdc"] %}
    {{ a }}:
      type: gpt
      parts:
        - name: bios_grub
          start: 1024kiB
          end: 2048Kib
          flags:
            - bios_grub
        - name: boot
          start: 2048KiB
          end: 256Mib
          flags:
            - raid
        - name: data
          start: "{{ 256+ 2048 }}Mib"
          end: "100%"
          flags:
            - raid
      {% endfor %}
  mdadm:
      {% for a,b in [(0, 2), (1, 4)] %}
    "/dev/md{{ a }}":
      - level=1
      - raid-devices=2
      - /dev/vdb{{ b }}
      - /dev/vdc{{ b }}
      {% endfor %}
  format:
    /dev/md0:
      fstype: ext4
      opts: "-L ecs-boot"
    /dev/md1:
      fstype: ext4
      opts: "-L ecs-root"
  {% endload %}


  {{ storage_setup(custom_storage) }}

{% endif %}
