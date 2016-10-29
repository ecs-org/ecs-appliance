include:
  - appliance.network

/etc/postfix/main.cf:
  file.managed:
    - source: salt://appliance/postfix/main.cf
    - template: jinja
    - makedirs: true
    - defaults:
        dockerip: {{ dockerip }}
        dockernet: {{ dockernet }}
    - require:
      - sls: appliance.network

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
      - sls: network
    - watch:
      - file: /etc/postfix/main.cf
