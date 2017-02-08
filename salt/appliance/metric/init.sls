include:
  - .pghero
  - .prometheus

/usr/local/share/appliance/prepare-metric.sh:
  file.managed:
    - source: salt://appliance/metric/prepare-metric.sh
    - makedirs: true
