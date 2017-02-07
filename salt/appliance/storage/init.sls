/usr/local/share/appliance/prepare-storage.sh:
  file.managed:
    - source: salt://appliance/storage/prepare-storage.sh
    - mode: "0755"
    - makedirs: true
