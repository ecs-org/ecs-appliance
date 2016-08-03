include:
  - packer
  - qrcode
  - common

profile_packer:
  file.append:
    - name: /app/.profile
    - text: |
        export PACKER_CACHE_DIR=/tmp/packer_cache
    - require:
      - sls: common
      - sls: qrcode
      - sls: packer


upgrade_system:
  apt-get -y update
  apt-get -y install
  apt-get -y dist-upgrade --force-yes
