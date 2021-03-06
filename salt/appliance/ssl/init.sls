include:
  - appliance.directories
  - .snakeoil

/usr/local/share/appliance/prepare-ssl.sh:
  file.managed:
    - source: salt://appliance/ssl/prepare-ssl.sh
    - require:
      - sls: appliance.directories

# dehydrated is a letsencrypt shell client
/usr/local/etc/dehydrated/config:
  file.managed:
    - contents: |
        BASEDIR="/app/etc/dehydrated"
        WELLKNOWN="/app/etc/dehydrated/acme-challenge"
        HOOK="/usr/local/bin/dehydrated-hook.sh"
    - makedirs: true

/usr/local/bin/dehydrated:
  file.managed:
    - source: salt://appliance/ssl/dehydrated
    - mode: "0755"

/usr/local/bin/dehydrated-hook.sh:
  file.managed:
    - mode: "0755"
    - source: salt://appliance/ssl/dehydrated-hook.sh

{% for i in ['deploy-cert-as-root.sh', 'unchanged-cert-as-root.sh'] %}
/usr/local/sbin/{{ i }}:
  file.managed:
    - mode: "0755"
    - source: salt://appliance/ssl/{{ i }}
{% endfor %}

/etc/sudoers.d/newcert_auth:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        app ALL=(ALL) NOPASSWD: /usr/local/sbin/deploy-cert-as-root.sh
        app ALL=(ALL) NOPASSWD: /usr/local/sbin/unchanged-cert-as-root.sh

/app/etc/dehydrated:
  file.directory:
    - user: app
    - group: app
    - require:
      - sls: appliance.directories

{% for i in ['archive', 'accounts', 'acme-challenge', 'certs'] %}
/app/etc/dehydrated/{{ i }}:
  file.directory:
    - user: app
    - group: app
    - require:
      - file: /app/etc/dehydrated
{% endfor %}
