#!/bin/bash

usage() {
    cat << EOF
$(basename $0) --key keyfile       [options] output.iso
$(basename $0) --vagrant           [options] output.iso
$(basename $0) --custom custom.env [options] output.iso

purpose: creates a cidata cloud-init config iso.
+ "--key" configures a ssh publickeyfile for root as cloud-init parameter
+ "--vagrant" configures the insecure vagrant public key for the created vagrant user
+ "--custom" supply custom user-data for config iso

options:
+ "--install-devserver" to install the devserver on first startup
+ "--install-appliance" to install the appliance on first startup
+ "--grow-root" to grow root partition on first boot
    and install cloud-initramfs-growroot on first startup

EOF
    exit 1
}

vagrant_publickey="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
userdata=""
optional=""

cmd="$1"
shift
if test "$cmd" = "--vagrant"; then
    userdata="#cloud-config
users:
  - name: vagrant
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - $vagrant_publickey
"
elif test "$cmd" = "--key"; then
    if test ! -e "$1"; then echo "error: ssh publickeyfile $1 not found"; usage; fi
    userdata="#cloud-config
ssh_authorized_keys:
  - $(cat $1)
disable_root: false
"
    shift
elif test "$cmd" = "--custom"; then
    if test ! -e "$1"; then echo "error: custom env $1 not found"; usage; fi
    userdata="$(cat $1)"
    shift
else
    if test "$cmd" != ""; then echo "error: wrong argument $cmd"; fi
    usage
fi

for i in genisoimage openssl; do
    if ! which $i > /dev/null; then echo "error: $i not found"; usage; fi
done

if test "$1" = "--install-appliance"; then
    shift
    optional="${optional}
runcmd:
  - 'apt-get -y update && apt-get -y install git'
  - 'git clone https://github.com/ecs-org/ecs-appliance /app/appliance'
  - 'mkdir -p /etc/salt && cp /app/appliance/salt/minion /etc/salt/minion'
  - 'curl -o /tmp/bootstrap_salt.sh -L https://bootstrap.saltstack.com && chmod +x /tmp/bootstrap_salt.sh'
  - '/tmp/bootstrap_salt.sh -X; systemctl stop salt-minion; systemctl disable salt-minion'
  - 'salt-call state.highstate pillar=\'{\"appliance\": {\"enabled\": true}}\''
"
elif test "$1" = "--install-devserver"; then
    shift
    optional="${optional}
runcmd:
  - 'apt-get -y update && apt-get -y install git'
  - 'git clone https://github.com/ecs-org/ecs /app/ecs'
  - 'chmod +x /app/ecs/scripts; /app/ecs/scripts/install-devserver.sh --yes'
"
elif test "$1" = "--grow-root"; then
    shift
    optional="${optional}
resize_rootfs: True
packages:
  - cloud-initramfs-growroot
"

fi

if test "$1" = ""; then echo "error: missing output filename"; usage; fi
outputfilename="$1"
tempdir=$(mktemp -d)
if test ! -d $tempdir; then echo "ERROR: creating tempdir"; exit 1; fi

cat > $tempdir/user-data <<END
$userdata
$optional

END

# Create fake meta-data
cat > $tempdir/meta-data <<END
instance-id: iid-$(openssl rand -hex 8)
local-hostname: ubuntu-xenial

END

# Create the ISO
genisoimage \
    -quiet -volid cidata -joliet -rock -input-charset utf-8 -graft-points \
    -output "$outputfilename" \
    user-data=$tempdir/user-data \
    meta-data=$tempdir/meta-data
rm -r $tempdir
echo "Generated $outputfilename"
