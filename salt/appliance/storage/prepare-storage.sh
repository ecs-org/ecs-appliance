prepare_storage () {
    need_storage_setup=false
    for d in /data/etc /data/ecs-ca /data/ecs-gpg /data/ecs-pgdump \
        /data/ecs-storage-vault /data/postgresql /volatile/docker \
        /volatile/ecs-backup-test /volatile/ecs-cache /volatile/redis \
        /volatile/prometheus /volatile/alertmanager /volatile/grafana \
        /volatile/duplicity; do
        if test ! -d $d ; then
            echo "Warning: could not find directory $d"
            need_storage_setup=true
        fi
    done
    if test "$(findmnt -S "LABEL=ecs-volatile" -f -l -n -o "TARGET")" = ""; then
        if is_falsestr "$APPLIANCE_STORAGE_IGNORE_VOLATILE"; then
            echo "Warning: could not find mount for ecs-volatile filesystem"
            need_storage_setup=true
        fi
    fi
    if test "$(findmnt -S "LABEL=ecs-data" -f -l -n -o "TARGET")" = ""; then
        if is_falsestr "$APPLIANCE_STORAGE_IGNORE_DATA"; then
            echo "Warning: could not find mount for ecs-data filesystem"
            need_storage_setup=true
        fi
    fi
    if $need_storage_setup; then
        echo "calling appliance.storage setup"
        salt-call state.sls appliance.storage.setup --retcode-passthrough --return appliance
        err=$?
        if test "$err" -ne 0; then
            appliance_failed "Appliance Error" "Storage Setup: Error, appliance.storage setup failed with error: $err"
        fi
    fi
}

prepare_storagevault () {
    echo "writing storage vault keys to ecs-gpg"
    # wipe directory clean of *.gpg files, but not eg. random_seed and do not remove directory
    find /data/ecs-gpg -mindepth 1 -name "*.gpg*" -delete
    echo "$ECS_VAULT_ENCRYPT" | gpg --homedir /data/ecs-gpg --batch --yes --import --
    echo "$ECS_VAULT_SIGN" | gpg --homedir /data/ecs-gpg --batch --yes --import --
    chown -R 1000:1000 /data/ecs-gpg
}
