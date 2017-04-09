include:
  - docker

/usr/local/share/appliance/prepare-postfix.sh:
  file.managed:
    - source: salt://appliance/postfix/prepare-postfix.sh
    - makedirs: true

/etc/postfix/main.cf:
  file.managed:
    - source: salt://appliance/postfix/main.cf
    - template: jinja
    - makedirs: true
    - defaults:
        additional_ip: {{ salt['pillar.get']('docker:ip') }}
        additional_net: {{ salt['pillar.get']('docker:net') }}
        domain: {{ salt['pillar.get']('appliance:domain') }}

# remove if is file, because we switch to maildir
/var/mail/root:
  file.absent:
    - onlyif: test -f /var/mail/root
    - watch_in:
      - service: postfix

opendkim:
  pkg.installed:
    - pkgs:
      - opendkim
      - opendkim-tools

/etc/opendkim.conf:
  file.managed:
    - source: salt://appliance/postfix/opendkim.conf
    - template: jinja
    - defaults:
        additional_net: {{ salt['pillar.get']('docker:net') }}
        domain: {{ salt['pillar.get']('appliance:domain') }}

/etc/default/opendkim:
  file.managed:
    - source: salt://appliance/postfix/opendkim.default

{%- set dkimkey= salt['pillar.get']('appliance:dkim:key', False) or salt['cmd.run_stdout']('openssl genrsa 2048') %}
/etc/dkimkeys/dkim.key:
  file.managed:
    - user: opendkim
    - group: opendkim
    - mode: "0600"
    - makedirs: true
    - contents: |
{{ dkimkey|indent(8,True) }}

opendkim.service:
  service.running:
    - name: opendkim
    - enable: true
    - require:
      - pkg: opendkim
    - watch:
      - file: /etc/opendkim.conf
      - file: /etc/default/opendkim
      - file: /etc/dkimkeys/dkim.key

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
      - service: opendkim.service
      - sls: docker
    - watch:
      - file: /etc/postfix/main.cf
