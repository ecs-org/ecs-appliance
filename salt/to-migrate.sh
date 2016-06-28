config.vm.provision "shell", privileged:true, inline: <<-SHELL
  hostnamectl set-hostname #{$server_name}.local
  echo "127.0.0.1 #{$server_name}.local" >> /etc/hosts
  export DEBIAN_FRONTEND=noninteractive
  export LANG=en_US.UTF-8
  printf %b "LANG=en_US.UTF-8\nLANGUAGE=en_US:en\nLC_MESSAGES=POSIX\n" > /etc/default/locale
  locale-gen en_US.UTF-8 && dpkg-reconfigure locales
  sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades
  apt-get -y update
  apt-get -y install software-properties-common spice-vdagent cloud-initramfs-growroot git
  apt-get -y dist-upgrade --force-yes
SHELL
config.vm.provision "shell", privileged: true, inline: <<-SHELL
  echo "Defaults env_keep+='http_proxy'" > /etc/sudoers.d/10-env-http-proxy
  echo "Defaults env_keep+=SSH_AUTH_SOCK" > /etc/sudoers.d/10-env-ssh-auth-sock
  echo 'set salt-minion systemstart to manual, workaround saltbootstrap/vagrant issue'
  echo 'manual' > /etc/init/salt-minion.override
SHELL
#!/bin/bash

if test $PACKER_BUILDER_TYPE = 'virtualbox' ; then
    if type apt-get >/dev/null 2>&1; then
        echo "Installing VirtualBox guest additions (debian)"

        apt-get install -y linux-headers-$(uname -r) build-essential perl
        apt-get install -y dkms

        VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
        mount -o loop /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
        sh /mnt/VBoxLinuxAdditions.run --nox11
        umount /mnt
        rm /home/vagrant/VBoxGuestAdditions_$VBOX_VERSION.iso
    fi
fi
