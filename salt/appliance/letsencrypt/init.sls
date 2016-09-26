
/usr/local/bin/dehydrated:
  file.managed:
    - source: salt://letsencrypt/dehydrated
    - mode: "0775"

{% for i in ['acme-challenge', 'certs'] %}
/usr/local/etc/dehydrated/{{ i }}:
  file.directory:
    - makedirs: true
{% endfor %}

/usr/local/etc/dehydrated/config:
  file.managed:
    - contents: |
        BASEDIR="/usr/local/etc/dehydrated"
        WELLKNOWN="/usr/local/etc/dehydrated/acme-challenge"
        {%- for i, d in salt['pillar.get']('letsencrypt').iteritems() %}
          {%- if i not in ['domains', 'enable', 'config'] %}
        {{ i|upper }}="{{ d }}"
          {%- endif %}
        {%- endfor %}

/usr/local/etc/dehydrated/domains.txt:
  file.managed:
    - contents: |
        {%- for i in salt['pillar.get']('letsencrypt:domains', {}) %}
        {{ i }}
        {%- endfor %}
