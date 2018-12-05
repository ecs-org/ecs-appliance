
{% if grains['virtual'] == 'physical' %}

hardware-tools:
  pkg.installed:
    - pkgs:
      - mdadm
      - lvm2
      - smartmontools
      - nvme-cli
      - hdparm
      - lm-sensors

{% endif %}
