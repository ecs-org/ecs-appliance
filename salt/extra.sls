{# make variable install based on pillar values extra_packages & extra_states #}

{% if salt['pillar.get']('extra_states', False) %}
include:
  {%- for s in salt['pillar.get']('extra_states', []) %}
  - {{ s }}
  {% endfor %}
{% endif %}

{% if salt['pillar.get']('extra_packages', False) %}
  {% for pkg in salt['pillar.get']('extra_packages', []) %}
{{ pkg }}:
  pkg.installed
  {% endfor %}
{% endif %}
