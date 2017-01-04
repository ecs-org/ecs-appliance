{#
include:
  - .pghero
  - .prometheus
#}

# monitor docker, postgres, memcached, uwsgi, (redis), (both nginx),
# cpu-load, memory, disk-i/o, disk-free, container

{% from "appliance/metric/lib.sls" import metric_install %}

{{ metric_install('cadvisor') }}

{#

{{ metric_install('postgres_exporter') }}
{{ metric_install('node-exporter') }}
{{ metric_install('memcached_exporter') }}

#}
