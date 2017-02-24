#!/bin/bash
. /usr/local/share/appliance/appliance.include
. /usr/local/share/appliance/prepare-metric.sh

# remember start time
start_epoch_seconds=$(date +%s)

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
gosu app /bin/bash -c "set -o pipefail &&  \
    /usr/bin/pg_dump --encoding='utf-8' --format=custom -Z0 -d ecs | \
    /bin/gzip --rsyncable > ${dbdump}.new"
if test "$?" -ne 0; then
    sentry_entry "Appliance Backup" "backup error: could not create database dump" "error" \
        "$(service_status appliance-backup.service)"
    exit 1
fi
mv ${dbdump}.new ${dbdump}

# check if we need to remove duplicity cache files, because backup url changed
confdir=/root/.duply/appliance-backup
cachedir=/root/.cache/duplicity/duply_appliance-backup
if test -e $cachedir/conf; then
    cururl=$(cat $confdir/conf   | grep "^TARGET=" | sed -r 's/^TARGET=[ '\''"]*([^ '\''"]+).*/\1/')
    lasturl=$(cat $cachedir/conf | grep "^TARGET=" | sed -r 's/^TARGET=[ '\''"]*([^ '\''"]+).*/\1/')
    if test "$cururl" != "$lasturl"; then
        sentry_entry "Appliance Backup" "warning: different backup url, deleting backup cache directory"
        rm -r $cachedir
        mkdir -p $cachedir
    fi
fi
# add last backup config to cachedir, so we can detect if backup url has changed
cp $confdir/conf $cachedir/conf

# duplicity to thirdparty of /data/ecs-storage-vault, /data/ecs-pgdump
/usr/bin/duply /root/.duply/appliance-backup cleanup --force
if test "$?" -ne "0"; then
    sentry_entry "Appliance Backup" "duply cleanup error" "warning" \
        "$(service_status appliance-backup.service)"
fi
/usr/bin/duply /root/.duply/appliance-backup backup
if test "$?" -ne "0"; then
    sentry_entry "Appliance Backup" "duply backup error" "error" \
        "$(service_status appliance-backup.service)"
    exit 1
fi
/usr/bin/duply /root/.duply/appliance-backup purge-full --force
if test "$?" -ne "0"; then
    sentry_entry "Appliance Backup" "duply purge-full error" "warning" \
        "$(service_status appliance-backup.service)"
fi

# calculate used space
volumesizekb=$(( 25*1024))
volumes=$(/usr/bin/duply /root/.duply/appliance-backup/ status | \
    grep "Total number of contained volumes:" | \
    sed -r "s/[^:]+[^0-9]*([0-9]+)/\1/g" | \
    awk '{s+=$1} END {print s}')
backupspacekb=$(( volumes * volumesizekb ))

# calculate runtime
end_epoch_seconds=$(date +%s)
duration=$(( end_epoch_seconds - start_epoch_seconds ))

# create and export metric to prometheus
backup_running_time=$(mk_metric backup_running_time gauge "The number of seconds for a backup run" \
    $duration "" ${start_epoch_seconds}000)
backup_space_usage=$(mk_metric backup_space_usage gauge "The number of kilo-bytes used in backupspace" \
    $backupspacekb "volumes=\"$volumes\"")
metric_export backup "${backup_running_time}" "${backup_space_usage}"
