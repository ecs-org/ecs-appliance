include:
  - .lib

# monitor docker, postgres, memcached, uwsgi, (redis), (both nginx),
# cpu-load, memory, disk-i/o, disk-free, container

# uwsgi prometheus metric is exported from ecs.web container to localhost:1717 in docker-compose.yml
{{ metric_install('cadvisor') }}
{{ metric_install('postgres_exporter') }}
{{ metric_install('node-exporter') }}
{{ metric_install('memcached_exporter') }}
{{ metric_install('alertmanager') }}
{{ metric_install('prometheus') }}
