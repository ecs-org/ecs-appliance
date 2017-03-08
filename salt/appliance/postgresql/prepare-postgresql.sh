prepare_postgresql () {
    local mem_kb mem_mb pg_mb cores
    local MAX_CONNECTIONS SHARED_BUFFERS WORK_MEM EFFECTIVE_CACHE_SIZE
    local pgcfg=/etc/postgresql/9.5/main/postgresql.conf
    local template=/etc/postgresql/9.5/main/ecs.conf.template

    # tune postgresql to current vm memory and cores
    mem_kb=$(cat /proc/meminfo  | grep -i memtotal | sed -r "s/[^:]+: *([0-9]+) .*/\1/g")
    mem_mb=$(( mem_kb / 1024))
    cores=$(nproc)

    # memory available for postgresql tuning calculation
    #   we reserve 2,5gb plus 256mb per core out of scope for postgres because of other apps
    #   Range: 512MB < pg_mb
    pg_mb=$((mem_mb - 2560 - cores * 256))
    if test $pg_mb -le 512; then pg_mb=512; fi

    # max_connections: default = 100
    #   Minimum: (uwsgi:2+ cores)+ (smtpd:1)+ (celery-worker:cores)+ (pg_hero:3)+ (buffer:5)
    #   Range: 44 <= MAX_CONNECTIONS <= 100 (if cores <= 8)
    MAX_CONNECTIONS=$((4 + 32 + cores * 8))

    # shared_buffers: default = 128MB
    #   with 1GB or more of RAM, a reasonable starting value for shared_buffers
    #   is 25% of the memory in your system. This buffer directly affects the cache hit ratio
    SHARED_BUFFERS=$((pg_mb / 4))

    # work_mem: default = 4MB
    #   This size is applied to each and every sort done by each user, and
    #   complex queries can use multiple working memory sort buffers.
    #   Set to 50MB, have 30 queries, using 1.5GB of real memory,
    #   if a query involves doing merge sorts of 8 tables, that requires 8 times work_mem.
    #   Calculation is 4mb at 512pg_mb (which translates to 96 available work_mem buffers)
    #   Range: 4MB < WORK_MEM < 64MB
    WORK_MEM=$(((pg_mb - SHARED_BUFFERS) * 1024 / 96 / cores))
    if test $WORK_MEM -lt 4096; then WORK_MEM=4096; fi
    if test $WORK_MEM -gt 65536; then WORK_MEM=65536; fi

    # effective_cache_size: default= 4GB
    #   Setting effective_cache_size to 1/2 of total memory
    #   would be a normal conservative setting, and 3/4 of memory is a more
    #   aggressive but still reasonable amount.
    #   Range: 2048MB < EFFECTIVE_CACHE_SIZE
    EFFECTIVE_CACHE_SIZE=$((3 * pg_mb / 4))
    if test $EFFECTIVE_CACHE_SIZE -lt 2048; then EFFECTIVE_CACHE_SIZE=2048; fi

    # typify values
    SHARED_BUFFERS="${SHARED_BUFFERS}MB"
    WORK_MEM="${WORK_MEM}kB"
    EFFECTIVE_CACHE_SIZE="${EFFECTIVE_CACHE_SIZE}MB"

    cp ${pgcfg} ${pgcfg}.org
    cat ${pgcfg}.org | \
        sed '/### ECS-CONFIG-BEGIN ###/,/### ECS-CONFIG-END ###/d' | \
        cat - $template | \
        sed -r "s/##MAX_CONNECTIONS##/$MAX_CONNECTIONS/g;s/##EFFECTIVE_CACHE_SIZE##/$EFFECTIVE_CACHE_SIZE/g" | \
        sed -r "s/##WORK_MEM##/$WORK_MEM/g;s/##SHARED_BUFFERS##/$SHARED_BUFFERS/g" > ${pgcfg}.new
    if ! diff -q ${pgcfg}.org ${pgcfg}.new; then
        echo "Changed postgresql ecs config"
        diff -u ${pgcfg}.org ${pgcfg}.new
        cp ${pgcfg}.new ${pgcfg}
        systemctl restart postgresql
    fi
}

prepare_database () {
    gosu postgres pg_isready --timeout=10
    if test $? -ne 0; then
        appliance_failed "Appliance Standby" "Appliance is in standby, postgresql is not ready after 10 seconds"
    fi
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
