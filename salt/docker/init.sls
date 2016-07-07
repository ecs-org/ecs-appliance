include:
  - common

docker:
  pkgrepo.managed:
    - repo: 'deb http://apt.dockerproject.org/repo ubuntu-xenial main'
    - humanname: "Ubuntu docker Repository"
    - file: /etc/apt/sources.list.d/docker-xenial.list
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: pgp.mit.edu
    - require:
      - pkg: ubuntu_ppa_support

  pkg.installed:
    - pkgs:
      - iptables
      - ca-certificates
      - lxc
      - cgroup-bin
      - docker-engine
    - require:
      - pkgrepo: docker

  file.managed:
    - name: /etc/default/docker
    - template: jinja
    - source: salt://docker/files/docker
    - context:
      docker: {{ s|d({}) }}

  service.running:
    - enable: true
    - require:
      - pkg: docker
      - cmd: docker-grub-settings
      - pip: docker-compose
    - watch:
      - file: docker

# enable cgroup memory and swap accounting, needs kernel restart
docker-grub-settings:
  file.managed:
    - name: /etc/default/grub.d/docker.cfg
    - makedirs: true
    - contents: |
        GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX cgroup_enable=memory swapaccount=1"
  cmd.run:
    - name: update-grub
    - watch:
      - file: docker-grub-settings

docker-compose:
  pkg.installed:
    - name: python
  pip.installed:
    - require:
      - pkg: docker-compose
