include:
  - common
  - packer
  - libvirt
  - qrcode

profile_packer:
  file.append:
    - name: /app/.profile
    - text: |
        export PACKER_CACHE_DIR=/tmp/packer_cache
    - require:
      - sls: common
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
      - sls: user
