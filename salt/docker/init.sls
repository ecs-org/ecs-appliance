include:
  - python

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

/etc/default/docker:
  file.managed:
    - contents: |
        DOCKER_OPTIONS="{{ salt['pillar.get']('docker:options', '') }}"
{%- if salt['pillar.get']('http_proxy', '') != '' %}
  {%- for a in ['http_proxy', 'HTTP_PROXY'] %}
        {{ a }}="{{ salt['pillar.get']('http_proxy') }}"
  {%- endfor %}
{%- endif %}

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

{% from "python/lib.sls" import pip2_install %}
{{ pip2_install('docker-compose') }}
