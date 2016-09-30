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
      - acpi
      - git
      - wget
      - curl
      - tmux
      - haveged

system_timezone:
  timezone.system:
    - name: {{ pillar['timezone'] }}
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
    - name: locale-gen en_US.UTF-8
    - watch:
      - file: /etc/default/locale

python3-yaml:
  pkg.installed:
    - require:
      - sls: python

/usr/local/bin/flatten_yaml.py:
  file.managed:
    - source: salt://common/flatten_yaml.py
    - mode: "0755"
    - require:
      - pkg: python3-yaml

/usr/local/etc/env.include:
  file.managed:
    - source: salt://common/env.include
