#!/bin/bash

usage(){
    cat << EOF
Usage:  $0 --yes-i-am-sure

recovers database and files from backup.

Requirements:
+ storage setup for target environment has already run
+ a valid environment with working backup config targeting the needed backup data
+ /data/ecs-storage-vault directory, must exist and be empty
+ /data/ecs-pgdump directory, must exist and be empty
+ postgresql database ecs must not exist

EOF
    exit 1
}

if test "$1" != "--yes-i-am-sure"; then
    usage
fi

# check a valid active environment with working backup config targeting the needed backup data
env-update.sh
. /usr/local/share/appliance/env.include
ENV_YML=/run/active-env.yml userdata_to_env ecs,appliance
if test $? -ne 0; then echo "error: could not activate userdata environment"; usage; fi

# check if existing and empty /data/ecs-storage-vault and /data/ecs-pgdump
for d in /data/ecs-storage-vault /data/ecs-pgdump; do
    if test ! -d $d; then
        echo "error: directory $d does not exist. run storage setup first";
        usage
    fi
    files_found=$(find $d -mindepth 1 -type f -exec echo true \; -quit)
    if test "$files_found" = "true"; then
        echo "error: directory $d is not empty. it must be empty"
        usage
    fi
done

# check if postgresql database ecs does not exist
gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw "$ECS_DATABASE"
if test $? -eq 0; then echo "error: database ecs exists."; usage; fi

echo "stop appliance, disable backup run"
systemctl stop appliance
rm /app/etc/tags/last_running_ecs
systemctl disable appliance-backup

echo "write duply config"
mkdir -p /root/.gnupg
find /root/.gnupg -mindepth 1 -name "*.gpg*" -delete
echo "$APPLIANCE_BACKUP_ENCRYPT" | gpg --homedir /root/.gnupg --batch --yes --import --
# write out backup target and gpg_key to duply config
gpg_key_id=$(gpg --keyid-format 0xshort --list-key ecs_backup | grep pub | sed -r "s/pub.+0x([0-9A-F]+).+/\1/g")
cat /root/.duply/appliance-backup/conf.template | \
    sed -r "s#^TARGET=.*#TARGET=$APPLIANCE_BACKUP_URL#;s#^GPG_KEY=.*#GPG_KEY=$gpg_key_id#" > \
    /root/.duply/appliance-backup/conf

echo "restore files and database dump from backup"
duply /root/.duply/appliance-backup restore /data

echo "import database from dump"
gosu postgres createuser app
gosu postgres createdb ecs -T template0 -l de_DE.utf8
gosu postgres psql -c "ALTER DATABASE ecs OWNER TO app;"
gosu app /bin/bash -c "cat ecs.pg_dump.gz | gzip -d | pg_restore -1 --format=custom --schema=public --no-owner --dbname=ecs"

exit 0

echo "configure and restart appliance"
rm /run/appliance-failed
systemctl start appliance-update

echo "reenable backup"
systemctl enable appliance-backup
