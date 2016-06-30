ppa_ubuntu_installer:
  pkg.installed:
    - pkgs:
      - python-software-properties
      - software-properties-common
      - apt-transport-https
    - order: 10

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

    hostnamectl set-hostname #{$server_name}.local
    echo "127.0.0.1 #{$server_name}.local" >> /etc/hosts

/etc/sudoers.d/ssh_auth:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        Defaults env_keep += "SSH_AUTH_SOCK"

packer_profile_settings:
  file.append:
    - name: /app/.profile
    - text: |
        export PACKER_CACHE_DIR=/tmp/packer_cache

setlocale:
  cmd.run:
    - name:

export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8
printf %b "LANG=en_US.UTF-8\nLANGUAGE=en_US:en\nLC_MESSAGES=POSIX\n" > /etc/default/locale
locale-gen en_US.UTF-8 && dpkg-reconfigure locales

sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades
apt-get -y update
apt-get -y install software-properties-common spice-vdagent cloud-initramfs-growroot git
apt-get -y dist-upgrade --force-yes

echo 'set salt-minion systemstart to manual, workaround saltbootstrap/vagrant issue'
echo 'manual' > /etc/init/salt-minion.override

{% if salt['pillar.get']('ecs:appliance:custom_storage', false) %}
{% from 'storage/lib.sls' import storage_setup with context %}
{{ storage_setup(salt['pillar.get']('ecs:appliance:custom_storage')) }}
{% endif %}
