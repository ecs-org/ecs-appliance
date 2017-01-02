monit:
  pkg.installed:
    - pkgs:
      - monit
  service.running:
    - name: monit
    - enable: True
    - require:
      - pkg: monit


+ only while ecs running, stop on stop

# shell
mem_kb=$(cat /proc/meminfo  | grep -i memtotal | sed -r "s/[^:]+: *([0-9]+) .*/\1/g")
mem_mb=$(( mem_kb / 1024))
cores=$(nproc)

# saltstack
{% set mem_mb = salt['grains.get']('mem_total') %}
{% set cores = salt['grains.get']('num_cpus') %}

+ depending nr of cores
check system $HOST
    if loadavg (5min) > 3 then alert
    if loadavg (15min) > 1 then alert
    if memory usage > 80% for 4 cycles then alert
    if swap usage > 20% for 4 cycles then alert
    # Test the user part of CPU usage
    if cpu usage (user) > 80% for 2 cycles then alert
    # Test the system part of CPU usage
    if cpu usage (system) > 20% for 2 cycles then alert
    # Test the i/o wait part of CPU usage
    if cpu usage (wait) > 80% for 2 cycles then alert
    # Test CPU usage including user, system and wait. Note that
    # multi-core systems can generate 100% per core
    # so total CPU usage can be more than 100%
    if cpu usage > 200% for 4 cycles then alert
