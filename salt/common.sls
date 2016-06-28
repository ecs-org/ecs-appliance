ppa_ubuntu_installer:
  pkg.installed:
    - pkgs:
      - python-software-properties
      - software-properties-common
      - apt-transport-https
    - order: 1

console-tools:
  pkg.installed:
    - pkgs:
      - haveged
      - acpi
      - tmux

SystemTimezone:
  timezone.system:
    - name: {{ pillar['timezone'] }}
    - utc: True

hostname:
  host:
    - present
    - name: {{ pillar['hostname'] }}
    - ip: 127.0.0.1
