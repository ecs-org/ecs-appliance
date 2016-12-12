#!/bin/bash
. /usr/local/share/appliance/appliance.include

# assure database exists
gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw ecs
if test $? -ne 0; then
    sentry_entry "Appliance Backup" "backup abort: Database ECS does not exist"
    exit 1
fi

# assure non empty ecs-storage-vault
files_found=$(find /data/ecs-storage-vault -mindepth 1 -type f -exec echo true \; -quit)
if test "$files_found" != "true"; then
    sentry_entry "Appliance Backup" "backup abort: ecs-storage-vault is empty"
    exit 1
fi

# pgdump to /data/ecs-pgdump
dbdump=/data/ecs-pgdump/ecs.pgdump.gz
gosu app /bin/bash -c "set -o pipefail; \
/usr/bin/pg_dump --encoding='utf-8' --format=custom -Z0 -d ecs | \
    /bin/gzip --rsyncable > ${dbdump}.new"
if test "$?" -ne 0; then
    sentry_entry "Appliance Backup" "backup error: could not create database dump"
    exit 1
fi
mv ${dbdump}.new ${dbdump}

# duplicity to thirdparty of /data/ecs-storage-vault, /data/ecs-pgdump
/usr/bin/duply /root/.duply/appliance cleanup --force
if test "$?" -ne "0"; then
    sentry_entry "Appliance Backup" "duply cleanup error" "warning" \
    "$(systemctl status -l -q --no-pager -n 20 appliance-backup.service | text2json)"
fi
/usr/bin/duply /root/.duply/appliance backup
if test "$?" -ne "0"; then
    sentry_entry "Appliance Backup" "duply backup error" "error" \
    "$(systemctl status -l -q --no-pager -n 20 appliance-backup.service | text2json)"
    exit 1
fi
/usr/bin/duply /root/.duply/appliance purge-full --force
if test "$?" -ne "0"; then
    sentry_entry "Appliance Backup" "duply purge-full error" "warning" \
    "$(systemctl status -l -q --no-pager -n 20 appliance-backup.service | text2json)"
fi
