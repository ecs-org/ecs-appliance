include:
  - appliance.network

postgresql:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-contrib
  service.running:
    - enable: true
    - require:
      - pkg: postgresql
      - sls: appliance.network
      - file: /etc/postgresql/9.5/main/pg_hba.conf
      - file: /etc/postgresql/9.5/main/postgresql.conf
    - watch:
      - file: /etc/postgresql/9.5/main/pg_hba.conf
      - file: /etc/postgresql/9.5/main/postgresql.conf

/etc/postgresql/9.5/main/pg_hba.conf:
  file.replace:
    - pattern: |
        ^host.*{{ pillar.get('docker:net') }}.*
    - repl: |
        host     ecs             app             {{ pillar.get('docker:net') }}           md5
    - append_if_not_found: true
    - require:
      - pkg: postgresql

/etc/postgresql/9.5/main/postgresql.conf:
  file.replace:
    - pattern: |
        ^.*listen_addresses.*
    - repl: |
        listen_addresses = 'localhost,{{ pillar.get('docker:ip') }}'
    - append_if_not_found: true
    - require:
      - pkg: postgresql
