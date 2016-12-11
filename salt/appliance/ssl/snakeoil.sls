include:
  - common.user

# regenerate snakeoil if key not existing or cn != hostname
generate_snakeoil:
  pkg.installed:
    - name: ssl-cert
  cmd.run:
    - name: make-ssl-cert generate-default-snakeoil --force-overwrite
    - onlyif: |
        test ! -e /etc/ssl/private/ssl-cert-snakeoil.key -o "$(openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -noout -text | grep Subject: | sed -re 's/.*Subject: .*CN=([^,]+).*/\1/')" != "$(hostname -f)"
    - require:
      - pkg: generate_snakeoil

/app/etc/snakeoil/ssl-cert-snakeoil.key:
  file.copy:
    - source: /etc/ssl/private/ssl-cert-snakeoil.key
    - mode: "0644"
    - makedirs: true
    - require:
      - cmd: generate_snakeoil

/app/etc/snakeoil/ssl-cert-snakeoil.pem:
  file.copy:
    - source: /etc/ssl/certs/ssl-cert-snakeoil.pem
    - mode: "0644"
    - require:
      - cmd: generate_snakeoil

/app/etc/snakeoil/ssl-snakeoil.conf:
  file.managed:
    - contents: |
        [ ca ]
        default_ca = snakeoil_ca

        [ snakeoil_ca ]
        private_key = ./ssl-ca-snakeoil.key
        certificate = ./ssl-ca-snakeoil.cert.pem
        database = ./index.txt
        serial = ./serial
        crlnumber = ./crlnumber
        new_certs_dir = .

        default_md = sha256
        preserve = no
        policy = policy_any

        default_bits = 2048
        default_days = 3650
        default_crl_days = 3650

        [ req ]
        default_bits = 2048
        distinguished_name = distinguished_snakeoil

        [ distinguished_snakeoil ]
        C = NO

        [ policy_any ]
        countryName            = optional
        stateOrProvinceName    = optional
        organizationName       = optional
        organizationalUnitName = optional
        commonName             = supplied
        emailAddress           = optional


/app/etc/snakeoil/index.txt:
  file:
    - touch

/app/etc/snakeoil/crlnumber:
  file.managed:
    - contents: |
        01
    - replace: false

/app/etc/snakeoil/ssl-ca-snakeoil.key:
  cmd.run:
    - cwd: /app/etc/snakeoil
    - name: openssl genrsa -out ssl-ca-snakeoil.key 2048
    - unless: test -f /app/etc/snakeoil/ssl-ca-snakeoil.key

/app/etc/snakeoil/ssl-ca-snakeoil.cert.pem:
  cmd.run:
    - cwd: /app/etc/snakeoil
    - name: openssl req -new -batch -x509 -config ssl-snakeoil.conf -key ssl-ca-snakeoil.key -out ssl-ca-snakeoil.cert.pem -subj "/CN=snakeoil/O=oilfactory"
    - unless: test -f /app/etc/snakeoil/ssl-ca-snakeoil.cert.pem

/app/etc/snakeoil/ssl-crl-snakeoil.pem:
  cmd.run:
    - cwd: /app/etc/snakeoil
    - name: openssl ca -gencrl -config ssl-snakeoil.conf -out ssl-crl-snakeoil.pem
    - unless: test -f /app/etc/snakeoil/ssl-crl-snakeoil.pem

# symlink to /app/ecs-ca which will get relocated to /data/ecs-ca
/app/etc/ca.cert.pem:
  file.symlink:
    - target: /app/ecs-ca/ca.cert.pem

/app/etc/crl.pem:
  file.symlink:
    - target: /app/ecs-ca/crl.pem

# defaults, only write if not existing
/app/ecs-ca/ca.cert.pem:
  file.copy:
    - replace: false
    - makedirs: true
    - source: /app/etc/snakeoil/ssl-ca-snakeoil.cert.pem
    - group: 1000
    - user: 1000

/app/ecs-ca/crl.pem:
  file.copy:
    - replace: false
    - makedirs: true
    - source: /app/etc/snakeoil/ssl-crl-snakeoil.pem
    - group: 1000
    - user: 1000

/app/etc/server.key.pem:
  file.copy:
    - replace: false
    - source: /app/etc/snakeoil/ssl-cert-snakeoil.key

/app/etc/server.cert.pem:
  file.copy:
    - replace: false
    - source: /app/etc/snakeoil/ssl-cert-snakeoil.pem

/app/etc/server.cert.dhparam.pem:
  file.copy:
    - replace: false
    - source: /app/etc/snakeoil/ssl-cert-snakeoil.pem
