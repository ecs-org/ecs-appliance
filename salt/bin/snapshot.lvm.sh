#!/bin/bash
usage() {
    cat << EOF
Usage: $0
    start volumegroup volumename snapshotname ["-","ro"]
    stop  volumegroup volumename snapshotname ["-","ro"]

"-": do not mount/unmount
"ro": do mount readonly

use "mount | grep snapshotname" for status

EOF
    exit 1
}

snapshotcreate() {
    # Args: $1= orgdev, $2 = shotvol  $3 = shotsize
    echo "Taking snapshot from $1 as $2 with size $3"
    /sbin/lvcreate -s --name $2 --size $3 $1
    iserr=$?

    if test 0 -eq $iserr ; then
       echo "Snapshot activated"
    else
       echo "ERROR: Error activating snapshot, lvcreate exited with $iserr"
       exit $iserr
    fi
}

snapshotremove() {
    # Args: $1 shotdev
    echo "Removing the snapshot device $1"
    /sbin/lvremove -f $1
    iserr=$?

    if test 0 -eq $iserr ; then
       echo "Snapshot deactivated"
    else
       echo "ERROR: Error deactivating snapshot, lvremove exited with $iserr"
       exit $iserr
    fi
}

verifymount() {
    # Args: $1=Shotmount
    # Verify the Mount Point exists, if not, create it
    if ! test -d "$1" ; then
        mkdir -p $1
        # Verify the Mount Point was created, if not exit
        if ! test -d "$1" ; then
            echo "ERROR: Could not create the mountpoint directory ($1)"
            exit 1
        fi
    fi
}

snapshotmount() {
    # Args: $1=shotdev , $2=shotmount, $3=mount options (default to "-o ro")
    SHOTDEV=$1
    SHOTMOUNT=$2
    if test "$3" = ""; then
        MOUNTPARAM="-o ro"
    else
        MOUNTPARAM=$3
    fi

    echo "Mount $SHOTDEV to the Mount Point $SHOTMOUNT using $MOUNTPARAM"
    mount $MOUNTPARAM $SHOTDEV $SHOTMOUNT
    iserr=$?

    if test 0 -eq $iserr ; then
        echo "Snapshot partition mounted"
    else
        echo "ERROR: Error mounting snapshot partition, mount exited with $iserr"
        exit $iserr
    fi
}

snapshotunmount() {
    # Args: $1=shotmount
    echo "Umounting Snapshot Volume $1"
    umount $1
}


command=$1
shift
if test "$command" != "start" -a "$command" != "stop" -a "$command" != "_test"; then
    echo "Error: Wrong usage." 1>&2
    usage
fi

LVMVG=$1
ORGVOL=$2
SNAPVOL=$3
SNAPPART="disk"
MOUNTBASE=/mnt
SHOTSIZE=6G
echo "LVMVG=$LVMVG , ORGVOL=$ORGVOL , SNAPVOL=$SNAPVOL , SNAPPART=$SNAPPART"

echo "Fixme: - , ro parameter unimplemented "
exit 1

case "$command" in
_test)
    echo "at `date`"
    snapshotcreate ${LVMVG}/${ORGVOL} ${SNAPVOL} ${SHOTSIZE}
    /sbin/kpartx -l -v /dev/mapper/${LVMVG}-${SNAPVOL}
    snapshotremove ${LVMVG}/${SNAPVOL}
    ;;
start)
    echo "startsnapshot at `date`"
    verifymount ${MOUNTBASE}/${SNAPVOL}_$SNAPPART
    snapshotcreate ${LVMVG}/${ORGVOL} ${SNAPVOL} ${SHOTSIZE}
    snapshotmount /dev/mapper/${LVMVG}-${SNAPVOL} ${MOUNTBASE}/${SNAPVOL}_${SNAPPART}
    ;;
stop)
    echo "stopsnapshot at `date`"
    snapshotunmount ${MOUNTBASE}/${SNAPVOL}_${SNAPPART}
    snapshotremove ${LVMVG}/${SNAPVOL}
    ;;
esac
