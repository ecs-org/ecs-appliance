bridge-utils:
  pkg.installed:
    - pkgs:
      - bridge-utils
      - iptables

docker0:
  network.managed:
    - type: bridge
    - enabled: true
    - ports: none
    - proto: static
    - ipaddr: {{ pillar.get('docker:ip') }}
    - netmask: {{ pillar.get('docker:netmask') }}
    - stp: off
    - require:
      - pkg: bridge-utils
    - require_in:
      - pkg: docker
