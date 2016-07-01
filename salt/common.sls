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
      - tmux

system_timezone:
  timezone.system:
    - name: {{ pillar['timezone'] }}
    - utc: True

set_hostname:
  host:
    - present
    - name: {{ pillar['hostname'] }}
    - ip: 127.0.0.1

    hostnamectl set-hostname #{$server_name}.local
    echo "127.0.0.1 #{$server_name}.local" >> /etc/hosts

/etc/sudoers.d/ssh_auth:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        Defaults env_keep += "SSH_AUTH_SOCK"

set_locale:
  cmd.run:
    - name:
  export LANG=en_US.UTF-8
  printf %b "LANG=en_US.UTF-8\nLANGUAGE=en_US:en\nLC_MESSAGES=POSIX\n" > /etc/default/locale
  locale-gen en_US.UTF-8 && dpkg-reconfigure locales

system_up2date:

  sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades
  apt-get -y update
  apt-get -y install software-properties-common spice-vdagent cloud-initramfs-growroot git
  apt-get -y dist-upgrade --force-yes

deactivate_saltminion:
  echo 'set salt-minion systemstart to manual, workaround saltbootstrap/vagrant issue'
  echo 'manual' > /etc/init/salt-minion.override
