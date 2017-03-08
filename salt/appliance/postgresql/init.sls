include:
  - docker
  - systemd.reload

/usr/local/share/appliance/prepare-postgresql.sh:
  file.managed:
    - source: salt://appliance/postgresql/prepare-postgresql.sh
    - makedirs: true

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
      - postgresql-9.5
      - postgresql-contrib
  service.running:
    - enable: true
    - require:
      - pkg: postgresql
      - cmd: late_postgresql.service
      - sls: docker
      - file: /etc/postgresql/9.5/main/pg_hba.conf
    - watch:
      - file: /etc/postgresql/9.5/main/pg_hba.conf

/etc/postgresql/9.5/main/pg_hba.conf:
  file.replace:
    - pattern: |
        ^host.*{{ salt['pillar.get']('docker:net') }}.*
    - repl: |
        host     all             app             {{ salt['pillar.get']('docker:net') }}           md5
    - append_if_not_found: true
    - require:
      - pkg: postgresql

/etc/postgresql/9.5/main/ecs.conf.template:
  file.managed:
    - source: salt://appliance/postgresql/ecs.conf.template

{% for p,r in [
  ("listen_addresses", "listen_addresses = 'localhost,"+ salt['pillar.get']('docker:ip')+ "'"),
  ("shared_preload_libraries", "shared_preload_libraries = 'pg_stat_statements'"),
  ("pg_stat_statements.track", "pg_stat_statements.track = all")
  ] %}

/etc/postgresql/9.5/main/postgresql.conf_{{ p }}:
  file.replace:
    - name: /etc/postgresql/9.5/main/postgresql.conf
    - pattern: |
        ^.*{{ p }}.*
    - repl: |
        {{ r }}
    - append_if_not_found: true
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql
    - require_in:
      - service: postgresql
{% endfor %}
