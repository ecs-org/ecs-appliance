include:
  - .pghero
  - .prometheus

/usr/local/share/appliance/prepare-metric.sh:
  file.managed:
    - source: salt://appliance/metric/prepare-metric.sh
    - makedirs: true

/app/grafana/dashboards:
  file.recurse:
    - source: salt://appliance/metric/dashboards
    - makedirs: true
