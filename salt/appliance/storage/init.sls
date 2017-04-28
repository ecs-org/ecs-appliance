include:
  - appliance.directories

/usr/local/share/appliance/prepare-storage.sh:
  file.managed:
    - source: salt://appliance/storage/prepare-storage.sh
    - require:
      - sls: appliance.directories
