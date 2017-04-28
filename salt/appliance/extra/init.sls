include:
  - appliance.directories

{# make variable install based on pillar values #}

{% if salt['pillar.get']('appliance:extra:states', False) %}
include:
  {%- for s in salt['pillar.get']('appliance:extra:states', []) %}
  - {{ s }}
  {% endfor %}
{% endif %}

{% if salt['pillar.get']('appliance:extra:packages', False) %}
appliance_extra_packages:
  pkg.installed:
    - pkgs:
  {% for pkg in salt['pillar.get']('appliance:extra:packages', []) %}
      - {{ pkg }}
  {% endfor %}
{% endif %}

/usr/local/share/appliance/prepare-extra.sh:
  file.managed:
    - source: salt://appliance/extra/prepare-extra.sh
    - require:
      - sls: appliance.directories
