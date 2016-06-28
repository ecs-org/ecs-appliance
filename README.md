## Partitioning

* default xenial cloud image partition layout:
  * dos-mbr
  * p1 Boot ext4 label cloudimg-rootfs (10G)
  * used space ~ 900MB
* create: mbr-p2 volatile (~10-50G) and mount to /volatile
* create: vg permanent (Big)
  * with a data volume (Big-15%)
  * and some freespace for snapshots
* Directories
```
/volatile
    /tmp
    /var/tmp
    /docker
    /ecs-log   # LOGFILE_DIR
    /ecs-cache # ECS_DOWNLOAD_CACHE_DIR
    /container/ecs-elasticsearch
    /container/redis
    /container/ecs-postfix
/data
    /ecs-storage-vault
    /container/ecs-postgres
    /dump/ecs-postgres
```


## vagrant appliance builder
+ create-ecs-config
    + creates a env.yml with all key material inside
    + see env.yml for Examples
    + creates a iso with user-data and meta-data for cloud-init
+ build-image --config machine.yml
    + create-build-config
        + create a machine.json with all key material inside (for using with packer)
    i: hardisk Layout: make mdadm raid1 on hda/hdb if both are present
+ upload-image image
+ deploy-image

## Appliance

### start appliance
+ look for user-data, load env.yml, put into environment
+ look if postgres-data is found /data/postgres-ecs/*
+ start ecs-postgres
+ no postgres-data or postgres-data but database is empty:
    ECS_RECOVER_FROM_BACKUP ?
      yes:  duplicity restore to /data/ecs-files and /tmp/pgdump
    ECS_RECOVER_FROM_DUMP ?
      yes:  pgimport from pgdump
    restored from somewhere ?
      premigrate (if old dump) and migrate
    not restored from dump ?
      yes: create new database
+ update letsencrypt
+ start all support container
+ start ecs.* container

### update-appliance
+ clone neweset git ecs-appliance to workdir
+ run update from there, update will move to /app

### database-migrate
+ if old PRE_MIGRATE snapshot exists, delete
+ snapshot ecs-database to "PRE_MIGRATE" snapshot
+ start ecs.web with migrate
+ add a onetime cronjob to delete PRE_MIGRATE snapshot after 1 week (which can fail if removed in the meantime)

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

### clone-ecs
+ snapshot ecs-files and ecs-database to CLONE R/W snapshot
+ start a clone compose with files and database from CLONE and modified settings
    (userswitcher, no emails)
+ add a onetime cronjob to shutdown clone and delete CLONE snapshot after 3 days

### cron-jobs
+ update letsencrypt
+ update sessions in ecs container
+ update packages (unattended-upgrades)
    + reboot machine if kernel update and sunday
+ update aux container
    + download all updated container
    + stop ecs-*
    + for every updated container:
        + stop container, migrate data (eg.pgcontainer), start container
    + start ecs.*
+ backup
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
