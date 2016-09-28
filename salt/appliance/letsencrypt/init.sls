
/usr/local/bin/dehydrated:
  file.managed:
    - source: salt://letsencrypt/dehydrated
    - mode: "0775"

/usr/local/etc/dehydrated/config:
  file.managed:
    - contents: |
        BASEDIR="/etc/appliance/dehydrated"
        WELLKNOWN="/etc/appliance/dehydrated/acme-challenge"
        {%- for i, d in salt['pillar.get']('appliance:letsencrypt:config', {}).iteritems() %}
        {{ i|upper }}="{{ d }}"
        {%- endfor %}

{% for i in ['acme-challenge', 'certs'] %}
/etc/appliance/dehydrated/{{ i }}:
  file.directory:
    - makedirs: true
{% endfor %}
