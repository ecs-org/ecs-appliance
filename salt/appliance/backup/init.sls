include:
  - systemd.reload

backup:
  pkg.installed:
    - pkgs:
      - duply
      - duplicity
      - lftp
      - gnupg

/root/.duply/appliance-backup/conf.template:
  file.managed:
    - source: salt://appliance/backup/duply.conf.template
    - makedirs: true

/root/.duply/appliance-backup/exclude:
  file.managed:
    - source: salt://appliance/backup/duply.files

/usr/local/share/appliance/appliance-backup.sh:
  file.managed:
    - source: salt://appliance/backup/appliance-backup.sh
    - mode: 0755

/etc/systemd/system/appliance-backup.timer:
  file.managed:
    - source: salt://appliance/backup/appliance-backup.timer
    - watch_in:
      - cmd: systemd_reload

/etc/systemd/system/appliance-backup.service:
  file.managed:
    - source: salt://appliance/backup/appliance-backup.service
    - watch_in:
      - cmd: systemd_reload

enable-appliance-backup-service:
  service.running:
    - name: appliance-backup.timer
    - enable: true
    - require:
      - pkg: backup
      - file: /etc/systemd/system/appliance-backup.service
      - file: /etc/systemd/system/appliance-backup.timer
      - file: /usr/local/share/appliance/appliance-backup.sh
      - file: /root/.duply/appliance-backup/conf
      - file: /root/.duply/appliance-backup/exclude
    - watch:
      - file: /etc/systemd/system/appliance-backup.service
      - file: /etc/systemd/system/appliance-backup.timer
