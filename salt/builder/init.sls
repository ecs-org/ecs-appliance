include:
  - common
  - user
  - packer
  - libvirt
  - qrcode

profile_packer:
  file.append:
    - name: /app/.profile
    - user: app
    - group: app
    - text: |
        export PACKER_CACHE_DIR=/tmp/packer_cache
    - require:
      - sls: common
      - sls: user
      - sls: packer

additional_builder_groups:
  user.present:
    - name: app
    - gid: app
    - home: /app
    - shell: /bin/bash
    - remove_groups: False
    - groups:
      - kvm
      - libvirtd
    - require:
      - sls: libvirt
