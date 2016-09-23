include:
  - python

docker-defaults:
  file.managed:
    - name: /etc/default/docker
    - template: jinja
    - source: salt://docker/docker.defaults
    - context:
      docker: {{ salt['pillar.get']('docker', {}) }}

docker-service:
  file.managed:
    - name: /etc/systemd/system/docker.service
    - source: salt://docker/docker.service

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

docker:
  pkgrepo.managed:
    - name: 'deb http://apt.dockerproject.org/repo ubuntu-xenial main'
    - humanname: "Ubuntu docker Repository"
    - file: /etc/apt/sources.list.d/docker-xenial.list
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: pgp.mit.edu

  pkg.installed:
    - pkgs:
      - iptables
      - ca-certificates
      - lxc
      - cgroup-bin
      - docker-engine
    - require:
      - pkgrepo: docker

  service.running:
    - enable: true
    - require:
      - pkg: docker
      - cmd: docker-grub-settings
      - pip: docker-compose
    - watch:
      - file: docker-defaults
      - file: docker-service

docker-compose:
  pip.installed:
    - require:
      - sls: python
