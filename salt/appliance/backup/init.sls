include:
  - systemd.reload

backup:
  pkg.installed:
    - pkgs:
      - duply
      - duplicity
      - lftp
      - gnupg

/root/.duply/appliance-backup/conf:
  file.managed:
    - source: salt://appliance/backup/duply.conf.template
    - template: jinja
    - makedirs: true
    - defaults:
        main_ip: {{ salt['network.get_route'](salt['network.default_route']('inet')[0].gateway).source }}

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
