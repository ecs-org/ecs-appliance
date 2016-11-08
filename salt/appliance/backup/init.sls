backup:
  pkg.installed:
    - pkgs:
      - duply
      - duplicity
      - lftp
      - gnupg


# https://sourceforge.net/projects/pgbarman/
# make dump

# su - postgres -s /bin/bash -c "set -o pipefail ; /usr/bin/pg_dump --format=custom --compress=0 ecs | /bin/gzip --rsyncable > '/var/backups/postgres/ecs.pg_dump.gz'"
