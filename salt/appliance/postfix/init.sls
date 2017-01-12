include:
  - docker

/etc/postfix/main.cf:
  file.managed:
    - source: salt://appliance/postfix/main.cf
    - template: jinja
    - makedirs: true
    - defaults:
        additional_ip: {{ salt['pillar.get']('docker:ip') }}
        additional_net: {{ salt['pillar.get']('docker:net') }}
        domain: {{ salt['pillar.get']('appliance:domain') }}

postfix:
  pkg.installed:
    - pkgs:
      - postfix
      - bsd-mailx
    - require:
      - file: /etc/postfix/main.cf
  service.running:
    - enable: true
    - require:
      - pkg: postfix
      - sls: docker
    - watch:
      - file: /etc/postfix/main.cf
