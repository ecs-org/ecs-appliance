libvirt:
  pkg.installed:
    - pkgs:
      - libvirt-bin
      - qemu-kvm
      - qemu-utils
      - cgroup-bin
      - bridge-utils
  service.running:
    - name: libvirt-bin
    - enable: True
    - require:
      - pkg: libvirt
