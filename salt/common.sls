salt-minion:
  service.dead:
    - enable: false

/etc/update-manager/release-upgrades:
  file.replace:
    pattern: "^Prompt=.*$"
    repl: Prompt=never

ubuntu_ppa_support:
  pkg.installed:
    - pkgs:
      - python-software-properties
      - software-properties-common
      - apt-transport-https
    - order: 10

base_packages:
  pkg.installed:
    - pkgs:
      - ca-certificates
      - haveged
      - acpi
      - git
      - wget
      - curl
      - tmux

system_timezone:
  timezone.system:
    - name: {{ pillar['timezone'] }}
    - utc: True

set_hostname:
  host.present:
    - name: {{ pillar['hostname'] }}
    - ip: 127.0.0.1

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
  cmd.run:
    - name: locale-gen en_US.UTF-8 && dpkg-reconfigure locales
    - require:
      - file: /etc/default/locale
