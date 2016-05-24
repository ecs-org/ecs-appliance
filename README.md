* xenial cloud image partition layout:
  * dos-mbr
  * p1 Boot ext4 label cloudimg-rootfs (10G)
  * used space ~ 900MB

* ecs-appliance:  /app/

* create
p2 volatile
  /volatile
    /tmp
    /var/tmp
    /docker
    LOGFILE_DIR => /ecs-log
    ECS_DOWNLOAD_CACHE_DIR => /ecs-cache
    /container/ecs-elasticsearch
    /container/redis

* make it:
other lvm
  lvm permanent
    /data
      /ecs-storage-vault
      /container/ecs-postgres
      /container/ecs-postfix
      /dump/ecs-postgres
  lvm freespace for snapshots


vagrant appliance builder:

  * create-ecs-config
    * creates a env.yml with all key material inside
    * see env.yml for Examples
    * creates a iso with user-data and meta-data for cloud-init
  * build-image --config machine.yml
    * create-build-config
      * create a machine.yml with all key material inside (for using with packer)
    i: hardisk Layout: make mdadm raid1 on hda/hdb if both are present

  * upload-image image
  * deploy-image


start appliance:
  look for user-data, load env.yml, put into environment

  look if postgres-data is found /data/postgres-ecs/*
  start ecs-postgres

  no postgres-data or postgres-data but database is empty:
    ECS_RECOVER_FROM_BACKUP ?
      yes:  duplicity restore to /data/ecs-files and /tmp/pgdump
    ECS_RECOVER_FROM_DUMP ?
      yes:  pgimport from pgdump
    restored from somewhere ?
      premigrate (if old dump) and migrate
    not restored from dump ?
      yes: create new database

  update letsencrypt
  start all support container
  start ecs.* container

update-appliance:
  clone neweset git ecs-appliance to workdir
  run update from there, update will move to /app

database-migrate:
  if old PRE_MIGRATE snapshot exists, delete
  snapshot ecs-database to "PRE_MIGRATE" snapshot
  start ecs.web with migrate
  add a onetime cronjob to delete PRE_MIGRATE snapshot after 1 week (which can fail if removed in the meantime)

update-ecs:
  build new ecs.* container
  stop ecs.*
  look if database migration is needed diff current/expected branch of *migrations*
    yes: database-migrate
  start ecs.*
  if not ok/started:
    stop ecs.*
    if was database-migrate
      stop database
      revert to PRE_migrate snapshot
    start old-container ecs.*

clone-ecs:
  snapshot ecs-files and ecs-database to CLONE R/W snapshot
  start a clone compose with files and database from CLONE and modified settings
    (userswitcher, no emails)
  add a onetime cronjob to shutdown clone and delete CLONE snapshot after 3 days

cron-jobs:
  .) update letsencrypt
  .) update sessions in ecs container
  .) update packages (unattended-upgrades)
    .) reboot machine if kernel update and sunday
  .) update aux container
    download all updated container
    stop ecs-*
    for every updated container:
      stop container, migrate data (eg.pgcontainer), start container
    start ecs.*
  .) backup
    assert non empty database
    assert non empty ecs-files
    pgdump to temp
    duplicity to thirdparty of ecs-files, pgdump and envsettings


* production prepare:
  build new container,
  make clone,
  migrate clone with new container
  run hitchtest
  if ok: set flag update_ready

* if createfirstuser:
  create user (group office) plus 1 Days certificate send to email address with transport password
  useremail,user first,last,gender, transportpass (min 15chars)

* meta-data setup
  * env config via: https://pypi.python.org/pypi/python-decouple


add https://prometheus.io/ for monitoring:
  * cadvisor support is built in
  * munin on root host and export for prometheus
    https://github.com/pvdh/munin_exporter
  * ? https://github.com/korfuri/django-prometheus
  * https://github.com/knyar/nginx-lua-prometheus
  * https://github.com/wrouesnel/postgres_exporter
  * https://github.com/oliver006/redis_exporter
  * for monitoring pdfas and mocca:
    * https://github.com/prometheus/jmx_exporter

  * ? https://github.com/kbudde/rabbitmq_exporter
  * ? https://github.com/cherti/mailexporter



### packages fit for python 3 and django and maybe useful
  * https://pypi.python.org/pypi/django-taggit
  * https://pypi.python.org/pypi/django-extensions/1.6.1
  * https://pypi.python.org/pypi/django-crispy-forms/1.5.2
  * https://pypi.python.org/pypi/django-model-utils
  * https://pypi.python.org/pypi/django-filter
  * https://pypi.python.org/pypi/django-braces
  * https://pypi.python.org/pypi/django-mptt
  * https://pypi.python.org/pypi/django-guardian
  * https://pypi.python.org/pypi/django-imagekit (no more pil if we need pictures)
  * https://www.djangopackages.com/packages/p/django-tastypie/

### Assets compression

  * https://pypi.python.org/pypi/django_compressor
  * https://pypi.python.org/pypi/django-pipeline

add piwik and others in front of:
 *.ecsname.org

* reintegrate pdfas, mocca, logrotate, duply

nginx does not support location based client certificates,
but client_cert_verify = optional, and export a variable.
We should use that variable within a middleware

mocca:static:all:https://joinup.ec.europa.eu/system/files/project/bkuonline-1.3.18.war:custom:bkuonline.war
pdfasconfig:static:all:https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.7/cfg/defaultConfig.zip:custom:pdf-as-web
pdfas:static:all:https://joinup.ec.europa.eu/site/pdf-as/releases/4.0.7/pdf-as-web-4.0.7.war:custom:pdf-as-web.war
wily has wkhtmltopdf in version 12.2.4-1, so no manual download is required
http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb

```
cat application.py | grep -E "[^:]+:[^:]+:[^:]+.*" | grep -v ^# | sed -re "s/[^:]+:([^:]+).*/\1/g" | sort | uniq
cat application.py | grep -E "[^:]+:[^:]+:[^:]+.*" | grep -v ^# > test.txt

cat test.txt | grep -E "([^:]+:)(instbin|static|static64|static32|req:apt).*" | sort
cat test.txt | grep -E "([^:]+:)(instbin|static|static64|static32).*" | grep -v ":win:" | sort

```

use ubuntu wily

vagrant box add http://cloud-images.ubuntu.com/vagrant/wily/current/wily-server-cloudimg-amd64-vagrant-disk1.box --name wily --checksum c87753b8e40e90369c1d0591b567ec7b2a08ba4576714224bb24463a4b209d1a --checksum-type sha256
vagrant mutate wily libvirt --input-provider virtualbox

https://piratenpad.de/p/SarTB5QEQ

https://hitchtest.readthedocs.org/en/latest/faq/how_does_hitch_compare_to_other_technologies.html
https://cookiecutter-django.readthedocs.org/en/latest/developing-locally.html
https://github.com/joke2k/django-environ
