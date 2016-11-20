{% from "python/lib.sls" import pip_install %}

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

# python3 packages needed for flatyaml and ravencat
# python2 packages needed for saltstack raven
{% for v in ['2', '3'] %}
python{{ v }}-common-packages:
  pkg.installed:
    - pkgs:
      - python{{ v }}-yaml
      - python{{ v }}-requests
    - require:
      - sls: python

{{ pip_install('raven', v) }}
{% endfor %}

{% for n in ['flatyaml.py', 'ravencat.py'] %}
/usr/local/bin/{{ n }}:
  file.managed:
    - source: salt://common/{{ n }}
    - mode: "0755"
{% endfor %}

# if we have a sentry_dsn set, to saltstack minon config
{% set sentry_dsn = salt['pillar.get']("appliance:sentry_dsn", false) or
  salt['pillar.get']("appliance:sentry:dsn", false) %}
requests+https

/etc/salt/minion:
  file.managed:
    - source: salt://minion

# replace https in sentry_dsn with requests+https to force transport via requests
sentry_config:
  file.blockreplace:
    - name: /etc/salt/minon
    - marker_start: "# START sentry config"
    - marker_end: "# END sentry config"
    - content: |
        # START sentry config
{%- if sentry_dsn %}
        sentry_handler:
          dsn: {{ sentry_dsn|replace("https:", "requests+https:") }}
          log_level: error
          site: {{ salt['pillar.get']('appliance:domain') }}
{%- endif %}
        # END sentry config
    - append_if_not_found: True
    - show_changes: True

/usr/local/etc/env.include:
  file.managed:
    - source: salt://common/env.include

/usr/local/sbin/generate-new-env.sh:
  file.managed:
    - source: salt://common/generate-new-env.sh
    - mode: "0755"
