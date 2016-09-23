
{% set docker_opts=[] %}
{% for s in salt['pillar.get']('docker:network:dns:server', []) %}
    {% do docker_opts.append('--dns='+ s) %}
{% endfor %}
{% if salt['pillar.get']('docker:network:dns:search', None) %}
    {% do docker_opts.append('--dns-search='+ pillar.docker.network.dns.search) %}
{% endif %}
{% if salt['pillar.get']('docker:network:bridge', None) %}
  {% do docker_opts.append('--bridge='+ pillar.docker.network.bridge) %}
{% endif %}
{% if salt['pillar.get']('docker:network:ipmasq', None) %}
  {% do docker_opts.append('--ip-masq='+ pillar.docker.network.ipmasq) %}
{% endif %}
{% if salt['pillar.get']('docker:storage:driver', None) %}
  {% do docker_opts.append('--storage-driver='+ pillar.docker.storage.driver) %}
{% endif %}
{% if salt['pillar.get']('docker:storage:dm', None) %}
  {% for o,d in pillar.docker.storage.dm.iteritems() %}
    {% do docker_opts.append('--storage-opt dm.'+ o+ '='+ d) %}
  {% endfor %}
{% endif %}
{% if salt['pillar.get']('docker:extra', None) %}
  {% do docker_opts.append(pillar.docker.extra) %}
{% endif %}


docker-defaults-docker_opts:
  file.replace:
    - name: /etc/default/docker
    - pattern: |
        ^#?DOCKER_OPTS=.*
    - repl: |
        DOCKER_OPTS="{{ docker_opts|join(' ') }}"
    - backup: False
    - append_if_not_found: True


{% if salt['pillar.get']('http_proxy', '') != '' %}
  {% for a in ['http_proxy', 'HTTP_PROXY'] %}
docker-defaults-{{ a }}:
  file.replace:
    - name: /etc/default/docker
    - pattern: |
        ^#?export {{ a }}=.*
    - repl: |
        export {{ a }}="{{ salt['pillar.get']('http_proxy') }}"
    - backup: False
    - append_if_not_found: True
  {% endfor %}
{% endif %}
