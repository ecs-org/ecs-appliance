# ECS-Appliance

## fixme
+ FIXME in ecs.settings current: ecs_require_client_certs

## knowhow
salt-call --local state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'

## Vagrant Appliance Builder

"vagrant up" installs all packages needed for builder

+ config new
    + creates a env.yml with all key material inside
    + see env.yml for Examples

+ config build
    + creates several iso's with user-data and meta-data for cloud-init
    + creates a pdf to print with qrcodes of the config data for offline storage

+ image build [provider]
    + calls packer to build a ecs machine
+ image upload [provider]
+ image deploy [provider]

+ deploy rescueshell_install user@host env.yml
    + ssh into target user@host,
    + partition harddisk as stated in env.yml
    + copy image files to harddisk,
    + copy env to harddisk

+ easy disaster recovery:
    deploying with a different env.yml using "ecs_recover_from_backup=True "

## Appliance

appliance gets build using packer


### start appliance
+ look for user-data, load env.yml, put into environment
+ start local nginx
+ update letsencrypt
+ run salt-call appliance.storage
  + look for storage, decide if need to partition storage
+ look if postgres-data is found /data/postgres-ecs/*
+ start local postgres
+ no postgres-data or postgres-data but database is empty:
    + ECS_RECOVER_FROM_BACKUP ?
        + yes: duplicity restore to /data/ecs-files and /tmp/pgdump
    + ECS_RECOVER_FROM_DUMP ?
        + yes: pgimport from pgdump
    + restored from somewhere ?
        + premigrate (if old dump) and migrate
    + not restored from dump ?
        + yes: create new database
+ compose start ecs.* container
+ change nginx config, reload

### start errors
+ service mode: just display info and wait, start nothing
    (get cert,self-sign if fail) display simple http&s page: Service not available
    + startup ("Appliance starting")
    + no user-data found ("no user-data found")
    + no storage found ("no storage found")
    + recover_from_backup but error while duplicity restore/connect ("recover from backup error")
    + update in progress ("Update in progress")
    + manual service ("Manual Service")

### update-appliance
+ clone neweset git ecs-appliance to workdir
+ run update from there, update will move to /app
+ run state.highstate

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
+ update letsencrypt
+ update sessions in ecs container
+ update packages (unattended-upgrades)
    + reboot machine if update-needs-restart and sunday
+ update aux container
    + download all updated container
    + stop ecs-*
    + for every updated container:
        + stop container, start container
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

### Partitioning
+ default xenial cloud image partition layout:
    + dos-mbr
    + p1 Boot ext4 label cloudimg-rootfs (10G)
    + used space ~ 900MB

### ENV



# set by builder
# version:
# git:
#   rev:
#   branch:

# used by devserver
# dev:
#   autostart: true
#   rebase_to: master
#   pghero_install: false

# only internal to settings.py
# this list is incomplete
# ca:
#   root: "os.path.join(project_dir, '..', 'ecs-ca')"
#   tracking:
#     enabled: false
#   download:
#     cache:
#       dir: "something"
