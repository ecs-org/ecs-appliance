prepare_postgresql () {
    local mem_kb mem_mb cores pg_mb
    local MAX_CONNECTIONS SHARED_BUFFERS WORK_MEM EFFECTIVE_CACHE_SIZE
    local pgcfg=/etc/postgresql/9.5/main/postgresql.conf
    #local template=/etc/postgresql/9.5/main/ecs.conf.template
    #fixme: disabled template until tested
    local template=/dev/null
    # tune postgresql to current vm memory and cores
    mem_kb=$(cat /proc/meminfo  | grep -i memtotal | sed -r "s/[^:]+: *([0-9]+) .*/\1/g")
    mem_mb=$(( mem_kb / 1024))
    cores=$(nproc)
    pg_mb=$((mem_mb - 1024 - cores * 1024)) # memory available for postgresql tuning
    if test "$pg_mb" -le 256; then pg_mb=256; fi
    MAX_CONNECTIONS=$((2+ cores+ 1+ cores+ 1+ 8)) # 1 core=14, 8 core=28
    SHARED_BUFFERS=$((pg_mb / 4))MB
    WORK_MEM=$((pg_mb / 4 * 1024 / MAX_CONNECTIONS))kB
    EFFECTIVE_CACHE_SIZE=$((192 * pg_mb/256))MB

    cp ${pgcfg} ${pgcfg}.org
    cat ${pgcfg}.org | \
        sed '/### ECS-CONFIG-BEGIN ###/,/### ECS-CONFIG-END ###/d' | \
        cat - $template | \
        sed -r "s/##MAX_CONNECTIONS##/$MAX_CONNECTIONS/g;s/##EFFECTIVE_CACHE_SIZE##/$EFFECTIVE_CACHE_SIZE/g" | \
        sed -r "s/##WORK_MEM##/$WORK_MEM/g;s/##SHARED_BUFFERS##/$SHARED_BUFFERS/g" > ${pgcfg}.new
    if ! diff -q ${pgcfg}.org ${pgcfg}.new; then
        echo "Changed postgresql ecs config"
        cp ${pgcfg}.new ${pgcfg}
        systemctl restart postgresql
    fi
}

prepare_database () {
    # check if ecs database exists
    gosu postgres psql -lqt | cut -d \| -f 1 | grep -qw "$ECS_DATABASE"
    if test $? -ne 0; then
        appliance_failed "Appliance Standby" "Appliance is in standby, no postgresql database named $ECS_DATABASE"
    fi
    if ! $(gosu postgres psql -c "\dg;" | grep app -q); then
        # create role app
        gosu postgres createuser app
    fi
    owner=$(gosu postgres psql -qtc "\l" |
        grep "^[ \t]*${ECS_DATABASE}" | sed -r "s/[^|]+\| +([^| ]+) +\|.*/\1/")
    if test "$owner" != "app"; then
        # set owner of ECS_DATABASE to app
        gosu postgres psql -c "ALTER DATABASE ${ECS_DATABASE} OWNER TO app;"
    fi
    if ! $(gosu postgres psql ${ECS_DATABASE} -qtc "\dx" | grep -q pg_stat_statements); then
        # create pg_stat_statements extension
        gosu postgres psql ${ECS_DATABASE} -c "CREATE extension pg_stat_statements;"
    fi
    pgpass=$(cat /app/etc/ecs/database_url.env 2> /dev/null | grep 'DATABASE_URL=' | \
        sed -re 's/DATABASE_URL=postgres:\/\/[^:]+:([^@]+)@.+/\1/g')
    if test "$pgpass" = ""; then pgpass="invalid"; fi
    if test "$pgpass" = "invalid"; then
        # set app user postgresql password to a random string and write to service_urls.env
        pgpass=$(HOME=/root openssl rand -hex 8)
        gosu postgres psql -c "ALTER ROLE app WITH ENCRYPTED PASSWORD '"${pgpass}"';"
        sed -ri "s/(postgres:\/\/app:)[^@]+(@[^\/]+\/).+/\1${pgpass}\2${ECS_DATABASE}/g" /app/etc/ecs/database_url.env
        # DATABASE_URL=postgres://app:invalidpassword@1.2.3.4:5432/ecs
    fi
}
