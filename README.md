# ECS-Appliance

the ecs appliance is a selfservice production setup virtual machine builder and executor.
it can be stacked on top of the developer vm, but is independend of it.

## upgrade your developer-vm

insert your devserver name (eg. "testecs") into your /etc/hosts:
    ```sudo -s 'printf "%s" "127.0.0.1 testecs" >> /etc/hosts'```

connect to your developer vm with port 80 and 443:
    ```sudo -E -P -u root ssh testecs -L 80:localhost:80 -L 443:localhost:443```

inside the developer vm:
```
git clone ssh://git@gogs.omoikane.ep3.at:10022/ecs/ecs-appliance.git /app/appliance
curl -o /app/bootstrap_salt.sh -L https://bootstrap.saltstack.com
sudo bash -c "mkdir -p /etc/salt; cp /app/appliance/salt/minion /etc/salt/minion; \
    chmod +x /app/bootstrap_salt.sh; /app/bootstrap_salt.sh -X; \
    systemctl stop salt-minion; systemctl disable salt-minion"
sudo salt-call state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'
sudo systemctl start appliance
```

### files of interest

Path | Description
--- | ---
/pillar/                    | environment
/pillar/top.sls             | defines the environment tree
/pillar/default-env.sls     | the fallback env yaml (localhost ecs config)
/salt/*.sls                 | states to be executed
/salt/top.sls               | defines the state tree
/salt/common/init.sls       | common install
/salt/appliance/init.sls    | ecs appliance install
/salt/appliance/appliance.service    | systemd appliance service (starts prepare and docker-compose)
/salt/appliance/prepare_appliance.sh | script started on ready to run appliance
/salt/appliance/prepare_ecs.sh       | script startet after prepare_appliance

## fixme
+ env.include does not work as nonroot if it tries to mount could-init iso's; should try sudo at mount umount

## Appliance

appliance gets build using packer

### Partitioning

+ default xenial cloud image partition layout:
    + dos-mbr
    + p1 Boot ext4 label cloudimg-rootfs (10G)
    + used space ~ 900MB naked , ~ 1700MB with ecs appliance (currently, will grow)

+ developer setup:
    + vagrantfile has grow-root baked into it, p1 will take all space, appliance will not create additional partitions
    + storage setup will (if told in env.yml) create the directories but do not expect a mountpoint

+ production setup:
    + storage.setup will (if told in env.yml):
        + add p2 (all usable space) as pv-lvm
        + add a vg and volumes ecs-data (60%) ecs-volatile (30%), rest is for snapshots

### start-appliance
+ see salt/appliance/appliance.service

### update-appliance
+ git fetch , git checkout in /app/appliance
+ run salt-call state.highstate

### update-ecs
+ systemctl restart appliance

### recover from backup
+ stop ecs.*
+ standby on
+ duplicity restore to /data/ecs*
+ pgimport /data/ecs-pgdump/ecs.pgdump
+ premigrate (if old dump) and migrate
+ call update-ecs

### clone-ecs
+ snapshot ecs-files and ecs-database to CLONE R/W snapshot
+ start a clone compose with files and database from CLONE and modified settings
    (userswitcher, no emails)
+ add a onetime cronjob to shutdown clone and delete CLONE snapshot after 3 days

### production prepare
+ build new container
+ make clone
+ migrate clone with new container
+ run hitchtest
+ if ok: set flag update_ready

### if createfirstuser:
+ create user (group office) plus 1 Day certificate send to email address with transport password
    + useremail,user first,last,gender, transportpass (min 15chars)

### ENV
```
# set by builder
version:
  git:
    rev:
    branch:

# used by devserver
dev:
    autostart: true
    rebase_to: master

```

## Vagrant Appliance Builder

`vagrant up` installs all packages needed for builder

add on top of developer-vm or appliance update:
`sudo salt-call state.highstate pillar='{"appliance": "enabled": true}}'`

+ builder config_new {outputfilename}
    + creates a env.yml with all key material inside
    + see env.yml for Examples

+ builder config_build {inputfilename}
    + creates several iso's with user-data and meta-data for cloud-init
    + creates a pdf to print with qrcodes of the config data for offline storage

+ builder rescueshell_install user@host env.yml
    + ssh into target user@host
        + partition harddisk as stated in env.yml
        + copy image files to harddisk,
        + copy env to harddisk
        + update grub
        + reboot

+ builder image_build [provider]
    + calls packer to build a ecs machine
