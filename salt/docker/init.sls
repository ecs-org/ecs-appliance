include:
  - python
  - systemd.reload

# pin docker to x.y.* release, so we get updates but no major new version
/etc/apt/preferences.d/docker-preferences:
  file.managed:
    - contents: |
        Package: docker.io
        Pin: version 18.09.*
        Pin-Priority: 900

# add docker options from pillar to etc/default config, add http_proxy if set
/etc/default/docker:
  file.managed:
    - contents: |
        DOCKER_OPTIONS="{{ salt['pillar.get']('docker:options', '') }}"
{%- if salt['pillar.get']('http_proxy', '') != '' %}
  {%- for a in ['http_proxy', 'HTTP_PROXY'] %}
        {{ a }}="{{ salt['pillar.get']('http_proxy') }}"
  {%- endfor %}
{%- endif %}

# enable cgroup memory and swap accounting, needs kernel restart
docker-grub-settings:
  file.managed:
    - name: /etc/default/grub.d/docker.cfg
    - makedirs: true
    - contents: |
        GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX cgroup_enable=memory swapaccount=1"
  cmd.wait:
    - name: update-grub
    - watch:
      - file: docker-grub-settings

docker-requisites:
  pkg.installed:
    - pkgs:
      - bridge-utils
      - iptables
      - ca-certificates
      - lxc
      - cgroup-bin

docker-network:
  network.managed:
    - name: docker0
    - type: bridge
    - enabled: true
    - ports: none
    - proto: static
    - ipaddr: {{ salt['pillar.get']('docker:ip') }}
    - netmask: {{ salt['pillar.get']('docker:netmask') }}
    - stp: off
    - require:
      - pkg: docker-requisites

docker-service:
  file.managed:
    - name: /etc/systemd/system/docker.service
    - source: salt://docker/docker.service
    - watch_in:
      - cmd: systemd_reload
    - require:
      - pkg: docker

remove_old_docker:
  file.absent:
    - name: /etc/apt/sources.list.d/docker-xenial.list
  cmd.run:
    - name: apt-get update --yes
    - onchanges:
      - file: remove_old_docker
  pkg.removed:
    - name: docker-engine
    - require:
      - cmd: remove_old_docker

docker:
  pkg.installed:
    - name: docker.io
    - require:
      - pkg: remove_old_docker
      - file: /etc/apt/preferences.d/docker-preferences
      - network: docker-network

  service.running:
    - enable: true
    - require:
      - pkg: docker
      - cmd: docker-grub-settings
      - pip: docker-compose
      - file: /etc/default/docker
      - file: docker-service
    - watch:
      - file: /etc/default/docker
      - file: docker-service

# XXX docker-3.2.1 docker-compose-1.21.0 create frontend nginx timeouts
# XXX docker-compose >= 1.27 dropped python2 support
docker-compose:
  file.managed:
    - name: /etc/default/docker-compose-constraint.txt
    - contents: |
        docker-compose <= 1.26.99

  pip.installed:
    - requirements: /etc/default/docker-compose-constraint.txt
    - bin_env: /usr/local/bin/pip2
    - require:
      - pkg: python
      - cmd: pip2-upgrade
      - file: docker-compose
