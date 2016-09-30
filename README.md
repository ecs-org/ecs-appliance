# ECS-Appliance


the ecs appliance is a selfservice production setup virtual machine builder and executor.
it can be stacked with the developer vm, but is independend of it.

## where to start

inside a developer vm:
```
git clone repositorypath /app/appliance
sudo mkdir -p /etc/salt
sudo cp /app/appliance/salt/minion /etc/salt/minon
curl -o bootstrap_salt.sh -L https://bootstrap.saltstack.com
sudo sh bootstrap_salt.sh
sudo salt-call --local state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'
sudo systemctl start appliance
```

files of interest:

/pillar/                    | environment
/pillar/top.sls             | defines the environment tree
/pillar/default-env.sls     | the fallback env yaml (localhost ecs config)
/salt/*.sls                 | states to be executed
/salt/top.sls               | defines the state tree
/salt/common/init.sls       | common install
/salt/appliance/init.sls    | install a ecs appliance
/salt/appliance/start.sh    | script started on ready to run appliance

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
    + storage setup will (if told so in env.yml)
        + just create the directories but do not expect a mountpoint

+ production setup:
    + storage.setup will (if told so in env.yml):
        + add p2 (all left space) as pv-lvm
        + add a vg and volumes ecs-data (60%) ecs-volatile (30%), rest is for snapshots

### start-appliance
+ see salt/appliance/start.sh

### update-appliance
+ git fetch , git checkout in /app/appliance
+ run salt-call state.highstate

### recover from backup
+ stop ecs.*
+ duplicity restore to /data/ecs*
+ pgimport /data/ecs-pgdump/ecs.pgdump
+ premigrate (if old dump) and migrate
+ call update-ecs

### update-ecs
+ build new ecs.* container
+ stop ecs.*
+ look if database migration is needed diff current/expected branch of *migrations*
    + yes: database-migrate
+ start ecs.*
+ if not ok/started:
    + stop ecs.*
    + if was database-migrate
        + stop database
        + revert to PRE_migrate snapshot
    + start old-container ecs.*

#### database-migrate
+ if old PRE_MIGRATE snapshot exists, delete
+ snapshot ecs-database to "PRE_MIGRATE" snapshot
+ start ecs.web with migrate
+ add a onetime cronjob to delete PRE_MIGRATE snapshot after 1 week (which can fail if removed in the meantime)

### clone-ecs
+ snapshot ecs-files and ecs-database to CLONE R/W snapshot
+ start a clone compose with files and database from CLONE and modified settings
    (userswitcher, no emails)
+ add a onetime cronjob to shutdown clone and delete CLONE snapshot after 3 days

### cron-jobs
+ local: update letsencrypt
+ ecs-container: update/cleanup sessions
+ local: update packages (unattended-upgrades)
    + reboot machine if update-needs-restart and sunday
+ local: update aux container
    + download all updated container
    + stop ecs-*
    + for every updated container:
        + stop container, start container
    + start ecs.*
+ local: backup
    + assure non empty database
    + assure non empty ecs-files
    + pgdump to temp
    + duplicity to thirdparty of ecs-files, pgdump and envsettings

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
