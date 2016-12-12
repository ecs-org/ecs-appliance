# ECS-Appliance

the ecs appliance is a selfservice production setup virtual machine builder and executor.
it can be stacked on top of the developer vm, but is independent of it.

Contents:
+ [Installation](#install-appliance)
+ [Configuration](#configure-appliance)
+ [Maintenance](#maintenance)
+ [Development](#development)

## Install Appliance


### to empty xenial vm via ssh

on your local machine:

```
ssh root@target.vm.ip '/bin/bash -c "mkdir -p /app/.ssh"'
scp cloneecs_id_ed25519 root@target.vm.ip:/app/.ssh/id_ed25519
scp target.domain.name.env.yml root@target.vm.ip:/app/env.yml
```

on empty target vm:

```
apt-get -y update
apt-get -y install git

GIT_SSH_COMMAND="ssh -i /app/.ssh/id_ed25519 " git clone \
    ssh://git@gogs.omoikane.ep3.at:10022/ecs/ecs-appliance.git /app/appliance

cd /
mkdir -p /etc/salt
cp /app/appliance/salt/minion /etc/salt/minion
curl -o /tmp/bootstrap_salt.sh -L https://bootstrap.saltstack.com
chmod +x /tmp/bootstrap_salt.sh
/tmp/bootstrap_salt.sh -X

chmod 0600 /app/env.yml
cp /app/env.yml /run/active-env.yml
salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
gosu postgres createdb ecs -T template0 -l de_DE.utf8
# look at appliance service, if not starting
reboot
```

### using vagrant

+ copy env.yml to the git repository root
+ Execute `vagrant up`
+ login into machine using `vagrant ssh`
+ become root `sudo -i`
+ create database: `gosu postgres createdb ecs -T template0 -l de_DE.utf8`
+ copy env: `cp /app/appliance/env.yml /app/env.yml`
+ update and start appliance: `reboot`

### upgrade developer vm

on developer vm:

```
# install appliance, clone appliance code
git clone ssh://git@gogs.omoikane.ep3.at:10022/ecs/ecs-appliance.git /app/appliance
# install saltstack
curl -o /tmp/bootstrap_salt.sh -L https://bootstrap.saltstack.com
sudo bash -c "mkdir -p /etc/salt; cp /app/appliance/salt/minion /etc/salt/minion; \
    chmod +x /tmp/bootstrap_salt.sh; /tmp/bootstrap_salt.sh -X; \
sudo salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
```

if you also want the builder (for building the appliance image) installed:

```
sudo salt-call state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'
```

### upgrade a xenial desktop

This is the same procedure as for the developer vm,
but be aware that compared to a typical desktop the appliance
configures strange things, enables and take over services.

+ postgres data is relocated to /data/postgresql
+ docker data is relocated to /volatile/docker
+ a app user is created with homedir /app
+ postgresql config, postgres user "app" and database "ecs"
    + set password of user app for tcp connect to postgresql
    + does not drop any data, unless told
+ docker and docker container
    + stops all container on relocate
    + expects docker0 to be the default docker bridge with default ip values
+ overwrites nginx, postfix, postgresql, stunnel configuration
+ listens on default route interface on ports 22,25,80,443,465

### Build Disk Image of unconfigured Appliance

appliance gets build using packer.

+ `vagrant up` installs all packages needed for builder
    + to add builder on top of developer-vm or appliance:
        + `sudo salt-call state.highstate pillar='{"builder": "enabled": true}}'`


## Configure Appliance

### for a development server
+ login in devserver
+ make a development env.yml: `cp /app/appliance/salt/pillar/default-env.sls /app/env.yml`
+ edit your settings in /app/env.yml and change your domainname

### for a production server

on your local machine:
+ vagrant up
+ make a new env.yml: `env-new.sh domainname.domain /app/`
+ edit your settings in /app/env.yml
+ build env into different formats: `env-build.sh /app/env.yml`
+ print out /app/env.yml.pdf
+ save and keep env.yml.tar.gz.gpg
+ copy env.yml to appliance /app/env.yml

on the target appliance vm:
+ copy env.yml from local machine to target vm at /app/env.yml
+ login into appliance
+ create a empty ecs database: `sudo -u postgres createdb ecs -T template0  -l de_DE.utf8`

## Start, Stop & Update Appliance
+ Start appliance: `systemctl start appliance`
+ Stop appliance: `systemctl stop appliance`
+ Update Appliance (appliance and ecs): `systemctl start update-appliance`

### Recover from failed state

if the appliance.service enters fail state, it creates a file named
"/run/appliance_failed".

You have to remove this file using `rm /run/appliance_failed` before running
the service again using `systemctl restart appliance.service`

## Maintenance

+ activate /run/active-env.yml in current shell of appliance vm:
    + `. /usr/local/shared/appliance/env.include; ENV_YML=/run/active-env.yml userdata_to_env ecs,appliance`

+ enter a running ecs container:
    + `docker exec -it ecs_image[.startcommand]_1 /bin/bash`
        + image = ecs, mocca, pdfas, memcached, redis
        + ecs .startcommand = web, worker, beat, smtpd

    + enter a django shell_plus as app user in a running (eg. ecs_ecs.web_1) container:
        + `docker exec -it ecs_ecs.web_1 /start run ./manage.py shell_plus`

+ run a new django shell with correct environment but independent of other container
    +  `docker-compose -f /app/etc/ecs/docker-compose.yml run --no-deps ecs.web run ./manage.py shell_plus`

+ follow whole journal: `journalctl -f`
+ follow appliance log:
    + (this includes backend nginx, uwsgi, beat, worker, smtpd, redis, memcached, pdfas, mocca)
    + `journalctl -u appliance -f`
+ follow frontend nginx: `journalctl -u nginx -f`
+ follow prepare-appliance: `journalctl -u prepare-appliance -f`
+ search for salt-call output: `journalctl $(which salt-call)`

+ quick update appliance code:
    + `cd /app/appliance; gosu app git pull; salt-call state.highstate pillar='{"appliance": "enabled": true}}'`
+ read details of a container in yaml:
    + `docker inspect 1b17069fe3ba | python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' | less`

## Development

### Repository Layout

Path | Description
--- | ---
/pillar/*.sls                   | salt environment
/pillar/top.sls                 | defines the root of the environment tree
/pillar/default-env.sls         | fallback env yaml and example localhost ecs config
/salt/*.sls                     | salt states (to be executed)
/salt/top.sls                   | defines the root of the state tree
/salt/common/init.sls           | common install
/salt/common/env-template.yml   | template used to generate a new env.yml
/salt/common/env-new.sh         | cli for env generation
/salt/common/env-build.sh       | cli for building pdf,iso,tar.gz.gpg
/salt/appliance/init.sls        | ecs appliance install
/salt/appliance/scripts/prepare-env.sh       | script started first to read environment
/salt/appliance/scripts/prepare-appliance.sh | script started next to setup services
/salt/appliance/scripts/prepare-ecs.sh       | script started next to build container
/salt/appliance/scripts/update-appliance.sh  | user script to trigger appliance/ecs update
/salt/appliance/ecs/docker-compose.yml       | main container group definition
/salt/appliance/systemd/appliance.service    | systemd appliance service that ties all together

### Execution Order

```
[on start]
|
|-- prepare-env
|-- prepare-appliance
|   |
|   |-- optional: call salt-call state.sls storage
|---|
|
|-- prepare-ecs
|-- appliance
|   |
|   |-- docker-compose up
:
:   (post-start)
|-- appliance-cleanup

[on error]
|
|-- appliance-failed

[on update]
|
|-- update-appliance
|   |
|   |-- salt-call state.highstate
|   |-- systemctl restart appliance
```

### Runtime Layout

Application:

path | remark
--- | ---
/app/env.yml        | local (nocloud) environment configuration location
/app/ecs            | ecs repository used for container creation
/app/appliance      | ecs-appliance repository active on host
 |
/app/etc            | runtime configuration (symlink of /data/etc)
/app/etc/tags       | runtime tags
 |
/app/ecs-ca        | client certificate ca and crl directory
 | (symlink of /data/ecs-ca)
/app/ecs-gpg       | storage-vault gpg keys directory
 | (symlink of /data/ecs-gpg)
/app/ecs-cache | temporary storage directory
 | (symlink of /volatile/ecs-cache)
 |
/run/active-env.yml | current activated configuration
/run/appliance-failed | flag that needs to be cleared,
 | before a restart of a failed appliance is possible

Data & Volatile:

path | remark
--- | ---
/data | data to keep
/data/ecs-ca | symlink target of /app/ecs-ca
/data/ecs-gpg | symlink target of /app/ecs-gpg
/data/ecs-storage-vault | symlink target of /app/ecs-storage-vault
/data/etc        | symlink target of /app/etc
/data/ecs-pgdump | database migration dump and backup dump diretory
/data/postgresql | referenced from moved /var/lib/postgresql
/volatile  | data that can get deleted
/volatile/docker | referenced from moved /var/lib/docker
/volatile/ecs-cache | Shared Cache Directory
/volatile/ecs-backup-test | default target directory of unconfigured backup
/volatile/redis | redis container database volume

### Container Volume Mapping

hostpath | container | container-path
--- | --- | ---
/data/ecs-ca | ecs | /app/ecs-ca
/data/ecs-gpg | ecs | /app/ecs-gpg
/data/ecs-storage-vault | ecs | /app/ecs-storage-vault
/volatile/ecs-cache | ecs | /app/ecs-cache
/app/etc/server.cert.pem | pdfas/mocca | /app/import/server.cert.pem:ro

### Environment Mapping

Types of environments:
+ saltstack get the environment as pillar either from /run/active-env.yml or from a default
+ shell-scripts and executed programs from these shellscripts get a flattend yaml representation in the environment (see flatyaml.py) usually restricted to ecs,appliance tree of the yaml file

Buildtime Environment:
+ the build time call of `salt-call state.highstate` does not need an environment,
but will use /run/active-env.yml if available

Runtime Environment:
+ prepare-env
    + get a environment yaml from all local and network sources
    + writes the result to /run/active-env.yml
+ update-appliance, prepare-appliance, prepare-ecs, appliance.service
    + parse /run/active-env.yml
    + include defaults from appliance.include (GIT_SOURCE*)
+ Storage Setup (`salt-call state.sls storage.sls`) parses /run/active-env.yml
+ update-appliance will call `salt-call state.highstate` which will use /run/active-env.yml
+ appliance.service calls docker-compose up with active env from /run/active-env.yml
    + docker compose passes the following to the ecs/ecs* container
        + service_urls.env, database_url.env
        + ECS_SETTINGS
    + docker compose passes the following to the mocca and pdfas container
        + APPLIANCE_DOMAIN as HOSTNAME

### Partitioning

+ default xenial cloud image partition layout:
  + dos-mbr
  + p1 Boot ext4 label cloudimg-rootfs (10G)

+ developer setup:
  + Vagrantfile has grow-root baked into it, therefore p1 will take all space
  + appliance will not create additional partitions
  + storage setup will create the directories but do not expect a mountpoint

+ production setup:
  + appliance will (if told in env.yml) setup storage to desired partitioning
