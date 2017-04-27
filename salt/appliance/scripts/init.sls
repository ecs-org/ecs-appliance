
{% for i in ['appliance.include',
 'prepare-env.sh', 'prepare-appliance.sh', 'prepare-ecs.sh'] %}
/usr/local/share/appliance/{{ i }}:
  file.managed:
    - source: salt://appliance/scripts/{{ i }}
    - mode: "0755"
    - makedirs: true
{% endfor %}

{% for n in ['create-client-certificate.sh', 'create-internal-user.sh'] %}
/usr/local/sbin/{{ n }}:
  file.managed:
    - source: salt://appliance/scripts/{{ n }}
    - mode: "0755"
{% endfor %}
