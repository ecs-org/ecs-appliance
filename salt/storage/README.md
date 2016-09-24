# setup storage

Features:
 * parted:      (gpt/mbr) partition creation
 * mdadm:       raid creation
 * crypt:       luks partition creation
 * lvm: pv:     create a lvm pysical volume
 * lvm: vg:     create a lvm volume group
 * lvm: lv:     create or expand (+ fs expand) a lvm logical volume
 * format:      format partitions
 * mount:       mount partitions (persistent)
 * swap:        mount swap (persistent)
 * directories: skeleton directory creation
 * relocate:    relocate data and make a symlink from old to new location

**Warning**: lvm makes a difference if you use "g" or "G" for gigabyte.
  * g=GiB (1024*1024*1024) , G= (1000*1000*1000)

## Usage

```
{% load_yaml as data %}
lvm:
  lv:
    my_lvm_volume:
      vgname: vg0
      size: 2g
{% endload %}
{% from 'storage/lib.sls' import storage_setup with context %}
{{ storage_setup(data) }}
```

### Full example

```
storage:
  parted:
{% for a in ["/dev/vdb", "/dev/vdc"] %}
    {{ a }}:
      {# if you leave out type, no partition table will be recreated #}
      type: gpt {# or "mbr" for [ms]dos type boot record #}
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
        - name: reserved
          start: 256Mib
          end: "{{ 256+ 2048 }}Mib"
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
      - devices:
        - /dev/vdb{{ b }}
        - /dev/vdc{{ b }}
      {#
      - optional kwargs passed to mdadm.
      #}

{% endfor %}

  crypt:
    "/dev/md1":
      password: "my-useless-password"
      target: "cryptlvm"

  lvm:
    pv:
      - /dev/mapper/cryptlvm
    vg:
      vg0:
        - devices:
          - /dev/mapper/cryptlvm
        {#
        - optional kwargs passed to lvm.
        #}
    lv:
      host_root:
        vgname: vg0
        size: 2g
      host_swap:
        vgname: vg0
        size: 2g
      images:
        vgname: vg0
        size: 1g
      cache:
        vgname: vg0
        size: 1g

  format:
    /dev/md0:
      fstype: ext3
    /dev/mapper/vg0-host_root:
      fstype: ext4
      options: {# passed to mkfs #}
        - "-L my_root"
    /dev/mapper/vg0-host_swap:
      fstype: swap
    /dev/mapper/vg0-images:
      fstype: ext4
      options:
        - "-L images"
    /dev/mapper/vg0-cache:
      fstype: ext4

  mount:
    /mnt/images:
      device: /dev/mapper/vg0-images
      fstype: ext4
      mkmnt: true {# additional args for mount.mounted #}
    /mnt/cache:
      device: /dev/mapper/vg0-cache
      fstype: ext4
      mkmnt: true

  swap:
    - /dev/mapper/vg0-host_swap

  directories:
    /mnt/images:
      names:
        - "default"
        - "templates"
        - "iso"
        - "tmp"
      options: {# passed to file.directory #}
        - group: libvirtd
        - user: libvirt-qemu
        - dir_mode: 775
        - file_mode: 664
      onlyif: mountpoint -q /mnt/images

  relocate:
    /var/lib/libvirt:
      destination: /mnt/images
      copy_content: True
      watch_in: "service: apt-cacher-ng"
```

## Additional Parameter

directory:
  - "options" parameter: passed to file.directory
mount:
  - optional args for mount.mounted
format:
  - "options" parameter: passed to mkfs
lvm vg:
  - optional kwargs passed to lvm.vg_present
lvm lv:
  - optional kwargs passed to lvm.lv_present
mdadm:
  - optional kwargs passed to mdadm.raid_present

Example:
```
  lvm:
    lv:
      test:
        vgname: vg0
        size: 10g
        wipesignatures: yes
```

### for "lvm: lv", "format", "directories", "relocate"
  * parameter: watch_in/require_in/require/watch
    if set will insert a "watch/require/_in" into the state

Example:
```
  relocate:
    /var/cache/apt-cacher-ng:
      destination: /mnt/cache
      copy_content: false
      watch_in: "service: apt-cacher-ng"
```

### for "directories"
  * parameter: onlyif/unless
    * will insert a onlyif/unless state requirement

Example:
```
  directories:
    /mnt/images:
      options:
        - user: libvirt-qemu
        - group: libvirtd
        - dir_mode: 2775
      names:
        - default
        - iso
        - templates
        - tmp
      onlyif: mountpoint -q /mnt/images
```

### for "lvm:lv"
  * parameter: expand
    * if set to true and volume exists,
      it will try to expand the existing lv to the desired size,
      ignoring any other parameters beside size and vgname.
      if lv does not exist it will create it with all parameters attached.
      if the lv exists and has a filesystem of ext2,ext3 or ext4 already on it,
      the filesystem will be resized.

Example:
```
  lvm:
    lv:
      cache:
        vgname: vg0
        size: 12g
        expand: true
```
