# ECS-Appliance

the ecs appliance is a selfservice production setup virtual machine builder and executor.
it can be stacked on top of the developer vm, but is independend of it.

## upgrade your developer-vm

on your local machine:

+ insert your devserver name (eg. "testecs") into your /etc/hosts

```
sudo -s 'printf "%s" "127.0.0.1 testecs" >> /etc/hosts'
```

+ connect to your developer vm with port 80 and 443:

```
sudo -E ssh -F ~/.ssh/config testecs -L 80:localhost:80 -L 443:localhost:443 -L 8050:localhost:8050
```

inside the developer vm:

+ install appliance

```
# clone appliance code
git clone ssh://git@gogs.omoikane.ep3.at:10022/ecs/ecs-appliance.git /app/appliance
# install saltstack
curl -o /app/bootstrap_salt.sh -L https://bootstrap.saltstack.com
sudo bash -c "mkdir -p /etc/salt; cp /app/appliance/salt/minion /etc/salt/minion; \
    chmod +x /app/bootstrap_salt.sh; /app/bootstrap_salt.sh -X; \
    systemctl stop salt-minion; systemctl disable salt-minion"
# execute appliance install
sudo salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
```

if you also want the builder (for building the appliance image) installed:

```
sudo salt-call state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'
```

## upgrade your xenial desktop

it is the same procedure as with the developer vm,
but be aware that the appliance takes over the following services:

+ postgresql config, postgres user "app" and database "ecs"
  + set password of user ecs for tcp connect to postgresql
  + does not drop any data, unless told
+ docker and docker container (stops all container at salt-call state.highstate, expects docker0 to be the default docker bridge with default ip values)
+ nginx configuration
+ postfix configuration
+ listens to port 25,80,443,465


## configure appliance
+ FIXME describe howto make env.yml

## start appliance
+ start appliance: `sudo systemctl start appliance`
+ open your browser and go to: http://testecs or http://localhost
+ stop appliance: `sudo systemctl stop appliance`

### files of interest

Path | Description
--- | ---
/pillar/                    | salt environment
/pillar/top.sls             | defines the root of the environment tree
/pillar/default-env.sls     | fallback env yaml and example localhost ecs config
/salt/*.sls                 | states (to be executed)
/salt/top.sls               | defines the root of the state tree
/salt/common/init.sls       | common install
/salt/appliance/init.sls    | ecs appliance install
/salt/appliance/appliance.service    | systemd appliance service (starts prepare and docker-compose)
/salt/appliance/prepare-appliance.sh | script started on ready to run appliance
/salt/appliance/prepare-ecs.sh       | script startet after prepare_appliance


### environment

#### Buildtime

* salt-call state.highstate (the install part) does not need an environment, but has a default one

#### Runtime
* prepare-appliance tries to get a environment yaml from all local and network sources
  * writes the filtered result ("ecs,appliance") to /app/active-env.yml
  * Storage Setup (`salt-call state.sls storage.sls`) expects /app/active-env.yml
* prepare-ecs and the appliance.service both parse /app/active-env.yml
* appliance service calls docker-compose up with active-env
  * docker compose passes service_urls.env and the current $ECS_SETTINGS to the ecs container
  * $APPLIANCE_DOMAIN is passed as HOSTNAME to mocca and pdfas

### unsorted commands of interest
+ reInstall appliance `sudo salt-call state.highstate pillar='{"appliance": "enabled": true}}'`
+ update appliance `sudo update-appliance` (more or less like git pull with state.highstate)
+ update ecs `sudo update-ecs`
+ read container details in yaml `docker inspect 1b17069fe3ba | python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' | less`
+ run a django shell `docker-compose run --no-deps ecs.web run ./manage.py shell_plus`
+ look at all appliance http status pages: `git grep "\(noupdate\|appliance\)_\(exit\|status\)"  | grep '"' | sed -re 's/[^"]+"(.*)/\1/g' | sort`
+ enter a running ecs container:
  + `sudo docker exec -it ecs_something.something_1` /bin/bash
+ enter the shell_plus in a running (eg. ecs_ecs.web_1) container:
  + `sudo docker exec -it ecs_ecs.web_1 /start run ./manage.py shell_plus`
+ start the shell_plus in a new container
  + `sudo docker run `
+ line and word count appliance:

```
wc `find . -regex ".*\.\(sls\|yml\|sh\|json\|conf\|template\|include\|md\|service\|identity\)" `

returns 3450 10440 97382 in total

```

## Appliance

appliance gets build using packer

### Partitioning

+ default xenial cloud image partition layout:
    + dos-mbr
    + p1 Boot ext4 label cloudimg-rootfs (10G)
    + used space ~ 900MB naked , ~ 1700MB with ecs appliance (currently, will grow)

+ developer setup:
    + vagrantfile has grow-root baked into it, p1 will take all space, appliance will not create additional partitions
    + storage setup will create the directories but do not expect a mountpoint

+ production setup:
    + storage.setup will (if told in env.yml):
        + add p2 (all usable space) as pv-lvm
        + add a vg and volumes ecs-data (60%) ecs-volatile (30%), rest is for snapshots

### still to be implemented

#### Vagrant Appliance Builder

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

#### Appliance: recover from backup
+ stop ecs.*
+ standby on
+ duplicity restore to /data/ecs*
+ pgimport /data/ecs-pgdump/ecs.pgdump
+ premigrate (if old dump) and migrate
+ call update-ecs

#### Appliance: clone-ecs
+ snapshot ecs-files and ecs-database to CLONE R/W snapshot
+ start a clone compose with files and database from CLONE and modified settings
    (userswitcher, no emails)
+ add a onetime cronjob to shutdown clone and delete CLONE snapshot after 3 days

#### Appliance: production prepare
+ build new container
+ make clone
+ migrate clone with new container
+ run hitchtest
+ if ok: set flag update_ready

#### if createfirstuser:
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
