include:
  - .pghero
  - .prometheus

/usr/local/share/appliance/prepare-metric.sh:
  file.managed:
    - source: salt://appliance/storage/prepare-metric.sh
    - mode: "0755"
    - makedirs: true
