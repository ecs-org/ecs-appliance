prepare_backup () {
    # create ready to use /root/.gnupg for backup being done using duplicity
    mkdir -p /root/.gnupg
    find /root/.gnupg -mindepth 1 -name "*.gpg*" -delete
    echo "$APPLIANCE_BACKUP_ENCRYPT" | gpg --homedir /root/.gnupg --batch --yes --import --
    # write out backup target and gpg_key to duply config
    gpg_key_id=$(gpg --keyid-format 0xshort --list-key ecs_backup | grep pub | sed -r "s/pub.+0x([0-9A-F]+).+/\1/g")
    cat /root/.duply/appliance-backup/conf.template | \
        sed -r "s#^TARGET=.*#TARGET=$APPLIANCE_BACKUP_URL#;s#^GPG_KEY=.*#GPG_KEY=$gpg_key_id#" > \
        /root/.duply/appliance-backup/conf
}
