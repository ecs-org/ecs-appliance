{% from "python/lib.sls" import pip2_install, pip3_install %}

include:
  - .user
  - python

# we use only masterless salt, so no minion is needed
salt-minion:
  service.dead:
    - enable: False
    - order: 10

ubuntu_ppa_support:
  pkg.installed:
    - pkgs:
      - python-software-properties
      - software-properties-common
      - apt-transport-https
    - order: 10

# upgrade everything, but stay on same release
update_system:
  file.replace:
    - name: /etc/update-manager/release-upgrades
    - pattern: "^Prompt=.*$"
    - repl: Prompt=never
  pkg.uptodate:
    - refresh: True

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
      - tmux

system_timezone:
  timezone.system:
    - name: {{ salt['pillar.get']('timezone') }}
    - utc: True

/etc/sudoers.d/ssh_auth:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        Defaults env_keep += "SSH_AUTH_SOCK"

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

# XXX double the default RateLimitBurst, appliance startup is noisy
/etc/systemd/journald.conf:
  file.replace:
    - pattern: ^RateLimitBurst=.*
    - repl: RateLimitBurst=2000
    - append_if_not_found: true
  cmd.run:
    - name: systemctl restart systemd-journald
    - onchanges:
      - file: /etc/systemd/journald.conf

/usr/local/etc/env.include:
  file.managed:
    - source: salt://common/env.include

/usr/local/sbin/generate-new-env.sh:
  file.managed:
    - source: salt://common/generate-new-env.sh
    - mode: "0755"

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

# standalone salt config, should be identical to the version used to bootstrap
/etc/salt/minion:
  file.managed:
    - source: salt://minion

# if we have a sentry_dsn set, add sentry to saltstack minon config
{% set sentry_dsn = salt['pillar.get']("appliance:sentry_dsn", false) or
  salt['pillar.get']("appliance:sentry:dsn", false) %}
# replace https in sentry_dsn with requests+https to force transport via requests
# curent saltstack 2016.3.1 has issue with non standard transport:
#   https://github.com/saltstack/salt/pull/34157
sentry_config:
  file.blockreplace:
    - name: /etc/salt/minion
    - marker_start: "# START sentry config"
    - marker_end: "# END sentry config"
    - content: |
{%- if sentry_dsn %}
        raven:
          dsn: {{ sentry_dsn|replace("https:", "requests+https:") }}
          tags:
            - os
            - saltversion
            - cpuarch
        sentry_handler_disabled:
          dsn: {{ sentry_dsn|replace("https:", "requests+https:") }}
          log_level: error
          site: {{ salt['pillar.get']('appliance:domain') }}
{%- endif %}

    - append_if_not_found: True
    - show_changes: True
