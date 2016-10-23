postgresql:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-contrib
  service.running:
    - enable: true
    - require:
      - pkg: postgresql
    - watch:
      - file: /etc/postgresql/9.5/main/postgresql.conf

/etc/postgresql/9.5/main/postgresql.conf:
  
