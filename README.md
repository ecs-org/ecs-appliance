# ECS-Appliance

the ecs appliance is a selfservice production setup virtual machine builder and executor.
it can be stacked on top of the developer vm, but is independent of it.

Contents:
+ [Installation](#install-appliance)
+ [Configuration](#configure-appliance)
+ [Maintenance](#maintenance)
+ [Development](#development)

## Install Appliance

The base of the appliance is Ubuntu Xenial (16.04).

You either need:
+ a already running Ubuntu Xenial and a ssh key to login
    + use any xenial cloud-image if you want to use the appliance in a cloud.
    + use the xenial server iso as a install image on your local hypervisor.
+ a local development machine with vagrant and a hypervisor for vagrant installed.
    + vagrant will setup the base machine for you

The partition layout should be flat with the 1 partition taking all space as root.

### ssh install to a empty xenial vm

on your local machine:

if cloning from a private repository,
copy the repository readonly ssh key to the target vm,
the saltstack part will correct permissions later.

```
ssh root@target.vm.ip '/bin/bash -c "mkdir -p /app/.ssh"'
scp id_ed25519 root@target.vm.ip:/app/.ssh/id_ed25519
```

on target vm:

+ clone from public repository
```
apt-get -y update; apt-get -y install git
git clone https://github.com/ethikkom/ecs-appliance /app/appliance
```

+ clone from private repository
```
apt-get -y update; apt-get -y install git
GIT_SSH_COMMAND="ssh -i /app/.ssh/id_ed25519 " git clone \
    ssh://git@gogs.target.domain:22/ecs/ecs-appliance.git /app/appliance
```

+ install saltstack and appliance software
```
cd /
mkdir -p /etc/salt
cp /app/appliance/salt/minion /etc/salt/minion
curl -o /tmp/bootstrap_salt.sh -L https://bootstrap.saltstack.com
chmod +x /tmp/bootstrap_salt.sh
/tmp/bootstrap_salt.sh -X
salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
reboot
```

### using vagrant

on your local machine:

+ clone ecs-appliance repository and start appliance install
```
git clone https://github.com/ethikkom/ecs-appliance ~/ecs-appliance
cd ~/ecs-appliance
vagrant up
```

### upgrade a developer vm

on a developer vm:

```
# either clone from public repository
git clone https://github.com/ethikkom/ecs-appliance /app/appliance

# or clone from private repository
git clone ssh://git@gogs.target.domain:22/ecs/ecs-appliance.git /app/appliance

# install saltstack and start appliance install
curl -o /tmp/bootstrap_salt.sh -L https://bootstrap.saltstack.com
sudo bash -c "mkdir -p /etc/salt; cp /app/appliance/salt/minion /etc/salt/minion; \
    chmod +x /tmp/bootstrap_salt.sh; /tmp/bootstrap_salt.sh -X; \
sudo salt-call state.highstate pillar='{"appliance": {"enabled": true}}'
```

if you also want the builder (for building the appliance image) installed:

```
sudo salt-call state.highstate pillar='{"builder": {"enabled": true}, "appliance": {"enabled": true}}'
```

### upgrade [empty] xenial desktop

This is the same procedure as for the developer vm,
but be aware that compared to a typical desktop the appliance
configures strange defaults, enables and take over services.

+ postgres data is relocated to /data/postgresql
+ docker data is relocated to /volatile/docker
+ a app user is created with homedir /app
+ postgresql config, postgres user "app" and database "ecs"
    + set password of user app for tcp connect to postgresql
    + does not drop any data, unless told
+ docker and docker container
    + stops all container on first installation
    + expects docker0 to be the default docker bridge with default ip values
+ overwrites nginx, postfix, postgresql, stunnel configuration
+ listens on default route interface on ports 22,25,80,443,465

### Build Disk Image of unconfigured Appliance

appliance gets build using packer.

+ `vagrant up` installs all packages needed for builder
    + to add builder on top of developer-vm or appliance:
        + `sudo salt-call state.highstate pillar='{"builder": "enabled": true}}'`


## Configure Appliance

### Initial Setup

#### for a development server

on your devserver:
+ make a development env.yml: `cp /app/appliance/salt/pillar/default-env.sls /app/env.yml`
+ edit your settings in /app/env.yml and change your domainname

#### for a production server

on your local machine:
+ vagrant up
+ make a new env.yml: `env-new.sh domainname.domain /app/`
+ edit your settings in /app/env.yml
+ build env into different formats: `env-build.sh /app/env.yml`
+ print out /app/env.yml.pdf
+ save and keep env.yml.tar.gz.gpg
+ copy env.yml to appliance /app/env.yml

```
ssh root@target.vm.ip '/bin/bash -c "mkdir -p /app/"'
scp env.yml root@target.vm.ip:/app/env.yml
```

#### for both

on the target vm:
```
# create a empty ecs database
sudo -u postgres createdb ecs -T template0  -l de_DE.utf8

# activate env and apply new environment settings
chmod 0600 /app/env.yml
cp /app/env.yml /run/active-env.yml
systemctl start appliance-update

# open a django management shell
docker exec -it ecs_ecs.web_1 /start run ./manage.py shell_plus

# create first internal office user
email='usermail@domain.name'; first_name='Firstname'; last_name='Lastname'; gender='m'

import math, string
from random import SystemRandom
from ecs.users.utils import create_user
PASSPHRASE_ENTROPY = 80
PASSPHRASE_CHARS = string.ascii_lowercase + string.digits
PASSPHRASE_LEN = math.ceil(PASSPHRASE_ENTROPY / math.log2(len(PASSPHRASE_CHARS)))

u = create_user(email, first_name=first_name, last_name=last_name)
p = u.profile
p.gender = gender
p.is_internal = True
p.save()
passphrase = ''.join(SystemRandom().choice(PASSPHRASE_CHARS) for i in range(PASSPHRASE_LEN))
u.set_password(passphrase)
print(passphrase)
u.save()
u.groups.add(Group.objects.get(name='EC-Office'))

# create a temporary client certificate for first office user and send it via email
cert, passphrase = Certificate.create_for_user('/tmp/user.p12', u, cn='Initial_Office_Cert1', days=60)
pkcs12 = open('/tmp/user.p12', 'rb').read()
from ecs.communication.mailutils import deliver
deliver(u.email, subject='Certificate', message='See attachment', from_email=settings.DEFAULT_FROM_EMAIL, attachments=(('user.p12', pkcs12, 'application/x-pkcs12'),), nofilter=True)
print(passphrase)
exit()

```

### Reconfigure a running Appliance

+ edit /app/env.yml
+ activate changes into current environment, call `env-update.sh`
+ optional: build new config package: call `env-build.sh /app/env.yml`
+ restart and apply new environment: `systemctl start appliance-update`

## Start, Stop & Update Appliance
+ Start appliance: `systemctl start appliance`
+ Stop appliance: `systemctl stop appliance`
+ Update Appliance (appliance and ecs): `systemctl start appliance-update`

### Recover from failed state

if the appliance.service enters fail state, it creates a file named
"/run/appliance_failed".

You have to remove this file using `rm /run/appliance_failed` before running
the service again using `systemctl restart appliance`

## Maintenance

All snippets expect root.

+ enter a running ecs container
    for most ecs commands it is not important to which
    instance (web,worker) you connect to, so ecs_ecs.web_1 is used in Examples

    + image = ecs, mocca, pdfas, memcached, redis
    + ecs .startcommand = web, worker, beat, smtpd

    + as root `docker exec -it ecs_image[.startcommand]_1 /bin/bash`
        + eg. `docker exec -it ecs_ecs.web_1 /bin/bash`
    + shell as app user with activated environment
        + `docker exec -it ecs_ecs.web_1 /start run /bin/bash`
    + manualy create a celery task:
        + `docker exec -it ecs_ecs.web_1 /start run celery --serializer=pickle -A ecs call ecs.integration.tasks.clearsessions`
    + celery events console
        + `docker exec -it ecs_ecs.web_1 /start run /bin/bash -c "TERM=screen celery -A ecs events"`
    + enter a django shell_plus as app user in a running container
        + `docker exec -it ecs_ecs.web_1 /start run ./manage.py shell_plus`

+ manual run letsencrypt client (do not call as root): `gosu app dehydrated --help`

+ destroy and recreate database
```
gosu app dropdb ecs
gosu postgres createdb ecs -T template0 -l de_DE.utf8
rm /app/etc/tags/last_running_ecs
systemctl restart appliance
```

+ quick update appliance code:
    + `cd /app/appliance; gosu app git pull; salt-call state.highstate pillar='{"appliance":{"enabled":true}}'; rm /var/www/html/503.html`

+ get cummulative cpu,mem,net,disk statistics of container:
    + `docker stats $(docker ps|grep -v "NAMES"|awk '{ print $NF }'|tr "\n" " ")`

+ read details of a container in yaml:
    + `docker inspect 1b17069fe3ba | python -c 'import sys, yaml, json; yaml.safe_dump(json.load(sys.stdin), sys.stdout, default_flow_style=False)' | less`

+ activate /run/active-env.yml in current shell of appliance vm:
    + `. /usr/local/share/appliance/env.include; ENV_YML=/run/active-env.yml userdata_to_env ecs,appliance`
    + to also set *GIT_SOURCE defaults: `. /usr/local/share/appliance/appliance.include` 

+ untested:
    +  `docker-compose -f /app/etc/ecs/docker-compose.yml run --no-deps ecs.web run ./manage.py shell_plus`
    + most spent time in high.state: `journalctl -u appliance-update | grep -B 5 -E "Duration: [0-9]{3,5}\."`

### Logging

Container:
+ all container log to stdout and stderr
+ docker has the logs of every container available
    + you can look at a log stream using eg. `docker logs ecs_ecs.web_1`
+ journald will get the container logs via the appliance.service which calls docker-compose
    + this includes backend nginx, uwsgi, beat, worker, smtpd, redis, memcached, pdfas, mocca
    + to follow use `journalctl -u appliance -f`

Host:
+ (nearly) all logging is going through journald
+ follow whole journal: `journalctl -f`
+ only follow service, eg. prepare-appliance: `journalctl -u prepare-appliance -f`
+ follow frontend nginx: `journalctl -u nginx -f`
+ search for salt-call output: `journalctl $(which salt-call)`

### Alerting

if ECS_SETTINGS_SENTRY_DSN and APPLIANCE_SENTRY_DSN is defined,
the appliance will report the following items to sentry:

+ python exceptions in web, worker, beat, smtpd
+ salt-call exceptions and state returns with error states
+ systemd service exceptions where appliance-failed is triggered,
    or appliance_failed, appliance_exit, sentry_entry is called

### Metrics

+ if APPLIANCE_METRIC_EXPORTER is set, metrics are exported from the subsystems
+ if APPLIANCE_METRIC_SERVER is set, these exported metrics are collected and stored by a prometheus server
+ if APPLIANCE_METRIC_GUI is set, a grafana server for displaying the collected metrics is available at http://localhost:3000
+ if APPLIANCE_METRIC_PGHERO is set, a pghero instance for postgres inspection is avaiable at http://localhost:5081 


Use ssh port forwarding to access the server ports 3000 and 5081, eg. "ssh root@hostname -L 3000:localhost:3000"

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
/salt/appliance/scripts/appliance-update.sh  | script triggerd from appliance-update.service
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
|-- appliance-update
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
/app/etc/flags      | runtime flags
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
/usr/local/share/appliance | scripts from the appliance salt source
/usr/local/[s]bin | user callable programs

Data:

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

Volatile:

path | remark
--- | ---
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
+ appliance-update, prepare-appliance, prepare-ecs, appliance.service
    + parse /run/active-env.yml
    + include defaults from appliance.include (GIT_SOURCE*)
+ Storage Setup (`salt-call state.sls storage.sls`) parses /run/active-env.yml
+ appliance-update will call `salt-call state.highstate` which will use /run/active-env.yml
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
