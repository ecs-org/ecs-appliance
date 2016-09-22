# transparent_hugepage: http://www.linux-kvm.org/wiki/images/9/9e/2010-forum-thp.pdf
# nohz: http://stackoverflow.com/questions/9775042/how-nohz-on-affects-do-timer-in-linux-kernel
libvirt-grub-settings:
  file.managed:
    - name: /etc/default/grub.d/libvirt.cfg
    - makedirs: true
    - contents: |
        GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX nohz=off transparent_hugepage=always"
  cmd.wait:
    - name: update-grub
    - watch:
      - file: libvirt-grub-settings

# KVM: vm.swappiness = 0 The kernel will swap only to avoid an out of memory condition
# Rationale: memory is given to the other domains, so we dont want the guest to manage the memory
vm.swappiness:
  sysctl.present:
    - value: 0

# KVM: useful for same page merging and huge pages on guest
vm.zone_reclaim_mode:
  sysctl.present:
    - value: 0

# disable netfilter arptables on linux bridges
net.bridge.bridge-nf-call-arptables:
  sysctl.present:
    - value: 0
