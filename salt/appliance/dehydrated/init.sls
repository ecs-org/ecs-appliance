
/usr/local/bin/dehydrated:
  file.managed:
    - source: salt://dehydrated/dehydrated
    - mode: "0755"

/usr/local/etc/dehydrated/config:
  file.managed:
    - contents: |
        BASEDIR="/etc/appliance/dehydrated"
        WELLKNOWN="/etc/appliance/dehydrated/acme-challenge"

{% for i in ['acme-challenge', 'certs'] %}
/etc/appliance/dehydrated/{{ i }}:
  file.directory:
    - makedirs: true
{% endfor %}
