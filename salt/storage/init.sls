{% if salt['grains.get']('pythonversion','')[0] == '3' %}
  {% from 'storage/lib3.sls' import storage_setup with context %}
{% else %}
  {% from 'storage/lib2.sls' import storage_setup with context %}
{% endif %}

{% if salt['pillar.get']('storage', {}) %}
{{ storage_setup(pillar.storage) }}
{% endif %}
