{% if pillar file ecs-user-data.yml exists, parse that instead %}

{% else %}
ecs:
  absolute_url_prefix: https://host.domain
  authorative_domain: host.domain
  allowed_hosts: host.domain
  secure_proxy_ssl: true

  debug: false
  sentry_dsn:
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
      email: user@example.org
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
      ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABQQDkGuAI7uACKaJkeSJGbUmLzGV6DQF/BJTWYhhzHKK7YHbHMMUGNK/AqYTaU301GPbzUaCfSkGlOJlmDEL7jWzZb81iTBt6uyRAv5PtPoyuugYkLIwmwBDqidlI/AaAaC8uDPAQcgGV+/4W+roDwO7LTdJDLZL7kDw5n1n5XgqLwjBASQRyTN3StePCzMEQvM21FbdmFberyK4LlEKU6a2p17T41cq7zOgbLut+1v6gAppuv0d6ZU0LFXUT1ABxueQdQeOwELvBBWbmkEFTMNWr54+4qReQhucxEMSnvIbTVvDTmCU8/71nSuVJZs5tCw9cDhWtN22AzrCLgjr88R4mp2xyH9ZE25IxtXwH+b8CQv/iHHdexy+9QTy4RR77pH929dhE3L0exgHrgJsMDgChEvgb/BPmpbcZ9RVyRoKpVQ== wuxxin@petit

{% endif %}
