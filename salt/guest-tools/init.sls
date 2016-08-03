
{% if grains['virtual'] in ['kvm', 'qemu', 'xen'] %}

spice-vdagent:
  pkg:
    - installed

{% elif grains['virtual'] == 'VirtualBox' %}

virtualbox-guest-dkms:
  pkg:
    - installed

{% endif %}
