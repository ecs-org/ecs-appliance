include:
  - docker

/etc/postfix/main.cf:
  file.managed:
    - source: salt://appliance/postfix/main.cf
    - template: jinja
    - makedirs: true
    - defaults:
        additional_ip: {{ pillar.get('docker:ip') }}
        additional_net: {{ pillar.get('docker:net') }}

postfix:
  pkg.installed:
    - pkgs:
      - postfix
    - require:
      - file: /etc/postfix/main.cf
  service.running:
    - enable: true
    - require:
      - pkg: postfix
      - sls: docker
    - watch:
      - file: /etc/postfix/main.cf
