{% from "python/lib.sls" import pip2_install, pip3_install %}

include:
  - .user
  - python

# we use only masterless salt, so no minion is needed
salt-minion:
  service.dead:
    - enable: False
    - order: 10

# standalone salt config, should be identical to the version used to bootstrap
/etc/salt/minion:
  file.managed:
    - source: salt://minion

# pin salt-stack to x.y.* release, so we get updates but no major new version
/etc/apt/preferences.d/saltstack-preferences:
  file.managed:
    - contents: |
        Package: salt-*
        Pin: version 2016.11.*
        Pin-Priority: 900

ubuntu_ppa_support:
  pkg.installed:
    - pkgs:
      - python-software-properties
      - software-properties-common
      - apt-transport-https
    - order: 10

# let upgrade stay on same release
update_system:
  file.replace:
    - name: /etc/update-manager/release-upgrades
    - pattern: "^Prompt=.*$"
    - repl: Prompt=never
    - onlyif: test -e /etc/update-manager/release-upgrades

base_packages:
  pkg.installed:
    - pkgs:
      - ca-certificates
      - acpid
      - haveged
      - curl
      - wget
      - rsync
      - gosu
      - git
      - socat
      - swaks
      - tmux
      - jq
      - lynx
      - mcedit

system_timezone:
  timezone.system:
    - name: {{ salt['pillar.get']('timezone') }}
    - utc: True

/etc/default/locale:
  file.managed:
    - contents: |
        LANG=en_US.UTF-8
        LANGUAGE=en_US:en
        LC_MESSAGES=POSIX

set_locale:
  cmd.wait:
    - name: locale-gen en_US.UTF-8 de_DE.UTF-8
    - watch:
      - file: /etc/default/locale

# journald: double the default RateLimitBurst, appliance startup is noisy
# journald: do not forward to syslog for storing, because we let journald store on disk
{% for p,r in [
  ("RateLimitBurst", "RateLimitBurst=2000"),
  ("ForwardToSyslog", "ForwardToSyslog=No"),
  ("Storage", "Storage=persistent"),
  ] %}

/etc/systemd/journald.conf_{{ p }}:
  file.replace:
    - name: /etc/systemd/journald.conf
    - pattern: |
        ^{{ p }}.*
    - repl: |
        {{ r }}
    - append_if_not_found: true
{% endfor %}

/etc/systemd/journald.conf:
  cmd.run:
    - name: systemctl restart systemd-journald
    - onchanges:
      - file: /etc/systemd/journald.conf

/etc/sudoers.d/ssh_auth:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        Defaults env_keep += "SSH_AUTH_SOCK"

/usr/local/share/appliance/env.include:
  file.managed:
    - source: salt://common/env.include
    - makedirs: True

{% for n in ['env-create.sh', 'env-package.sh', 'env-update.sh'] %}
/usr/local/sbin/{{ n }}:
  file.managed:
    - source: salt://common/{{ n }}
    - mode: "0755"
{% endfor %}

# python3 packages needed for flatyaml and ravencat
# python2 packages needed for saltstack raven
python-common-packages:
  pkg.installed:
    - pkgs:
      - python-yaml
      - python-requests
      - python3-yaml
      - python3-requests
    - require:
      - sls: python
{{ pip2_install('raven') }}
{{ pip3_install('raven') }}

{% for n in ['flatyaml.py', 'ravencat.py'] %}
/usr/local/bin/{{ n }}:
  file.managed:
    - source: salt://common/{{ n }}
    - mode: "0755"
{% endfor %}
