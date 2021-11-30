include:
  - python
  - systemd.reload

# pin docker to x.y.* release, so we get updates but no major new version
/etc/apt/preferences.d/docker-preferences:
  file.managed:
    - contents: |
        Package: docker-engine
        Pin: version 1.13.*
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
{%- if grains['virtual']|upper not in ['LXC', 'SYSTEMD-NSPAWN', 'NSPAWN'] %}
  cmd.wait:
    - name: update-grub
    - watch:
      - file: docker-grub-settings
{% endif %}

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

docker:
  pkgrepo.managed:
    - name: 'deb http://apt.dockerproject.org/repo ubuntu-xenial main'
    - humanname: "Ubuntu docker Repository"
    - file: /etc/apt/sources.list.d/docker-xenial.list
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: pgp.mit.edu

  pkg.installed:
    - pkgs:
      - docker-engine
    - require:
      - pkgrepo: docker
      - file: /etc/apt/preferences.d/docker-preferences
      - network: docker-network

  service.running:
    - enable: true
    - require:
      - pkg: docker
      - file: docker-grub-settings
      - pip: docker-compose
      - file: /etc/default/docker
      - file: docker-service
    - watch:
      - file: /etc/default/docker
      - file: docker-service

# XXX docker-3.2.1 docker-compose-1.21.0 create frontend nginx timeouts
docker-compose:
  file.managed:
    - name: /etc/default/docker-compose-constraint.txt
    - contents: |
        requests >= 2.14.2
        docker <= 3.1.99
        docker-compose <= 1.20.99

  pip.installed:
    - requirements: /etc/default/docker-compose-constraint.txt
    - bin_env: /usr/local/bin/pip2
    - require:
      - pkg: python
      - cmd: pip2-upgrade
      - file: docker-compose
