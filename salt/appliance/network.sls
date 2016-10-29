{% set dockerip="172.17.0.1" %}
{% set dockernet="172.17.0.1/16" %}
{% set dockernetmask="255.255.0.0" %}

docker0:
  network.managed:
    - type: bridge
    - enabled: true
    - ports: none
    - proto: static
    - ipaddr: {{ dockerip }}
    - netmask: {{ dockernetmask }}
    - stp: off
