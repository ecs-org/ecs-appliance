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

# add docker options to etc/default config, add http_proxy if set
{%- if grains['virtual']|upper in ['LXC', 'SYSTEMD-NSPAWN', 'NSPAWN'] %}
  # use vfs storage driver and systemd cgroup if running under same kernel virt
  {% set options='--bridge=docker0 --storage-driver=vfs --exec-opt native.cgroupdriver=systemd --log-driver=journald' %}
{% else %}
  {% set options='--bridge=docker0 --storage-driver=overlay2' %}
{% endif %}
/etc/default/docker:
  file.managed:
    - contents: |
        DOCKER_OPTIONS="{{ options }}"
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
{%- if grains['virtual']|upper in ['LXC', 'SYSTEMD-NSPAWN', 'NSPAWN'] %}
    - name: true
{% else %}
    - name: update-grub
{% endif %}
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

etc-network-interfaces:
  file.touch:
    - name: /etc/network/interfaces

docker-network:
  file.blockreplace:
    - name: /etc/network/interfaces
    - marker_start: |
        auto docker0
    - marker_end: |
            bridge_stp off
    - append_if_not_found: true
    - content: |
        iface docker0 inet static
            address {{ salt['pillar.get']('docker:ip') }}
            netmask {{ salt['pillar.get']('docker:netmask') }}
            bridge_fd 0
            bridge_maxwait 0
            bridge_ports none
    - require:
      - file: etc-network-interfaces
      - pkg: docker-requisites
  cmd.run:
    - name: ifup docker0
    - onchanges:
      - file: docker-network

docker-service:
  file.managed:
    - name: /etc/systemd/system/docker.service
    - source: salt://docker/docker.service
    - watch_in:
      - cmd: systemd_reload
    - require:
      - pkg: docker

{% if salt['file.file_exists']('/etc/apt/sources.list.d/docker-xenial.list') %}
{# use old setup if already installed, use included docker.io otherwise #}
docker:
  pkgrepo.managed:
    - name: 'deb http://apt.dockerproject.org/repo ubuntu-xenial main'
    - humanname: "Ubuntu docker Repository"
    - file: /etc/apt/sources.list.d/docker-xenial.list
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: pgp.mit.edu
    - require_in:
      - pkg: docker
  pkg.installed:
    - pkgs:
      - docker-engine
    - require:
      - file: /etc/apt/preferences.d/docker-preferences
      - cmd: docker-network

{% elif grains['virtual']|upper in ['LXC', 'SYSTEMD-NSPAWN', 'NSPAWN'] %}
other-docker:
  pkg.removed:
    - pkgs:
      - docker.io

docker:
  pkgrepo.managed:
    - name: 'deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable'
    - file: /etc/apt/sources.list.d/docker-ce-xenial.list
    - key_url: https://download.docker.com/linux/ubuntu/gpg
    - require_in:
      - pkg: docker
  pkg.installed:
    - pkgs:
      - docker-ce
      - docker-ce-cli
    - require:
      - cmd: docker-network

{% else %}
other-docker:
  pkg.removed:
    - pkgs:
      - docker-ce

docker:
  pkg.installed:
    - pkgs:
      - docker.io
    - require:
      - cmd: docker-network
{% endif %}

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
