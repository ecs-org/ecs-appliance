
console-tools:
  pkg.installed:
    - pkgs:
      - haveged
      - acpi
      - timezone
      - tmux

SystemTimezone:
  timezone.system:
    - name: {{ pillar['timezone'] }}
    - utc: True
