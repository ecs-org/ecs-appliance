
ecs:
  absolute_url_prefix: http://localhost
  authorative_domain: localhost
  allowed_hosts: localhost
  secure_proxy_ssl: false

  debug: true
  sentry_dsn:
  prometheus:
    enabled: true
  logo_border_color: green
  userswitcher:
    enabled: true
    parameter: "-it"

  database:
    migrate_auto: true

  email:
    filter_outgoing_mail: true
    backend: django.core.mail.backends.console.emailbackend
    limited_email_backend: django.core.mail.backends.console.emailbackend

  client:
    certs:
      required: true

  storage:
    volatile:
      device: vda
    permanent:
      device: vdb
      snapshot_type: lvm
    vault:
      encrypt:
        sec: |
            test
        pub: |
            test
      sign:
        sec: |
            test
        pub: |
            test

  backup:
    url: "proto://username:password@host.domain/path/to/data"
    encrypt_sec: |
        test
    encrypt_pub: |
        test

  recover:
    from_backup: false
    from_dump: false
    dump_filename: "" # if not empty, this file will be picked first

  firstrun:
    example_data: false
    user:
      email: user@localhost
      first: first
      last: last
      cert_pass: "pwgen 16"
      # creates a office group user with name first last, and email a@b.c
      # a certificate (valid for 24h) is created, crypted with cert_pass and send to a@b.c
      # user can then request "reset password" and get a password recreation link
      # login, save password, create and install a longlived certificate

  local_settings: |
      # test
      x=0
      z="jo"

  authorized_keys: |
      # insert your ssh-keys here
