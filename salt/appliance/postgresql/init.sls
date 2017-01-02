include:
  - docker
  - systemd.reload

# https://sourceforge.net/projects/pgbarman/

late_postgresql.service:
  file.managed:
    - name: /etc/systemd/system/late_postgresql.service
    - source: salt://appliance/postgresql/late_postgresql.service
    - watch_in:
      - cmd: systemd_reload
  cmd.wait:
    - name: systemctl enable late_postgresql.service
    - watch:
      - file: late_postgresql.service

postgresql:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-contrib
  service.running:
    - enable: true
    - require:
      - pkg: postgresql
      - cmd: late_postgresql.service
      - sls: docker
      - file: /etc/postgresql/9.5/main/pg_hba.conf
      - file: /etc/postgresql/9.5/main/postgresql.conf
    - watch:
      - file: /etc/postgresql/9.5/main/pg_hba.conf
      - file: /etc/postgresql/9.5/main/postgresql.conf

/etc/postgresql/9.5/main/pg_hba.conf:
  file.replace:
    - pattern: |
        ^host.*{{ salt['pillar.get']('docker:net') }}.*
    - repl: |
        host     all             app             {{ salt['pillar.get']('docker:net') }}           md5
    - append_if_not_found: true
    - require:
      - pkg: postgresql

/etc/postgresql/9.5/main/postgresql.conf:
  file.replace:
    - pattern: |
        ^.*listen_addresses.*
    - repl: |
        listen_addresses = 'localhost,{{ salt['pillar.get']('docker:ip') }}'
    - append_if_not_found: true
    - require:
      - pkg: postgresql

/etc/postgresql/9.5/main/ecs.conf.template:
  file.managed:
    - source: salt://appliance/postgresql/ecs.conf.template
