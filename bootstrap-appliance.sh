#!/bin/bash

usage(){
    cat << EOF
Usage:  $0 [--branch branchname] --yes

install the appliance from scratch.

EOF
    exit 1
}

branch=master
if test "$1" = "--branch"; then
    branch="$2"
    shift 2
fi
if test "$1" != "--yes"; then usage; fi

cd /tmp
export DEBIAN_FRONTEND=noninteractive
export LANG=en_US.UTF-8
timedatectl set-timezone "Europe/Vienna"
printf "LANG=en_US.UTF-8\nLANGUAGE=en_US:en\nLC_MESSAGES=POSIX\n" > /etc/default/locale

for i in apt-daily.service apt-daily.timer unattended-upgrades.service; do
    systemctl disable $i
    systemctl stop $i
    ln -sf /dev/null /etc/systemd/system/$i
done
systemctl daemon-reload

apt-get -y update
apt-get -y install software-properties-common locales git gosu curl
locale-gen en_US.UTF-8 de_DE.UTF-8 && dpkg-reconfigure locales

export HOME=/app
adduser --disabled-password --gecos ",,," --home "/app" app
cp -r /etc/skel/. /app/.
if test ! -f /app/appliance; then
    gosu app git clone https://github.com/ecs-org/ecs-appliance /app/appliance
fi
gosu app git -C /app/appliance fetch -a -p
gosu app git -C /app/appliance checkout -f $branch
gosu app git -C /app/appliance reset --hard origin/$branch

mkdir -p /etc/salt
cp /app/appliance/salt/minion /etc/salt/minion
curl -o /tmp/bootstrap_salt.sh -L https://bootstrap.saltstack.com
chmod +x /tmp/bootstrap_salt.sh
/tmp/bootstrap_salt.sh -X
salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
