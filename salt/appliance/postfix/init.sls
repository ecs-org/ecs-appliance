include:
  - appliance.network

/etc/postfix/main.cf:
  file.managed:
    - source: salt://appliance/postfix/main.cf
    - template: jinja
    - makedirs: true
    - defaults:
        additional_ip: {{ pillar.get('docker0_ip') }}
        additional_net: {{ pillar.get('docker0_net') }}
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
