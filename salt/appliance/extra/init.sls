include:
  - appliance.directories

/usr/local/share/appliance/prepare-extra.sh:
  file.managed:
    - source: salt://appliance/extra/prepare-extra.sh
    - require:
      - sls: appliance.directories

{# install additional packages from pillar #}
{% if salt['pillar.get']('appliance:extra:packages', False) %}
appliance_extra_packages:
  pkg.installed:
    - pkgs:
  {% for pkg in salt['pillar.get']('appliance:extra:packages', []) %}
      - {{ pkg }}
  {% endfor %}
{% endif %}

{# write additional files to disk from pillar #}
{% if salt['pillar.get']('appliance:extra:files', False) %}
  {% for i in salt['pillar.get']('appliance:extra:files', []) %}
appliance_extra_files_{{ i.path }}:
  file.managed:
    - name: {{ i.path }}
    {%- if i.owner|d(false) %}
    - user:  {{ i.owner.split(":")[0] }}
      {%- if i.owner.split(":")[1] != "" %}
    - group: {{ i.owner.split(":")[1] }}
      {%- endif %}
    {%- endif %}
    {%- if i.permissions|d(false) %}
    - mode:  {{ i.permissions }}
    {%- endif %}
    - contents: |
{%- if i.content|d(false) %}
{{ i.content|indent(8,True) }}
{%- else %}
{{ i.contents|indent(8,True) }}
{%- endif %}
    - require:
      - sls: appliance.directories
  {% endfor %}
{% endif %}

{# paste and execute salt state from pillar #}
{% if salt['pillar.get']('appliance:extra:states', False) %}
{{ salt['pillar.get']('appliance:extra:states') }}
{% endif %}
