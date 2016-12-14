include:
  - python


{% macro pip_install(package_or_packagelist, version="") %}
python{{ version }}-{{ package_or_packagelist }}:
  pip.installed:
  {%- if package_or_packagelist is iterable and package_or_packagelist is not string %}
    - pkgs: {{ package_or_packagelist}}
  {%- else %}
    - name: {{ package_or_packagelist }}
  {%- endif %}
  {%- if version %}
    - bin_env: {{ '/usr/bin/pip'+ version }}
  {%- endif %}
    - require:
      - sls: python
{% endmacro %}

{% macro pip3_install(package_or_packagelist) %}
{{ pip_install(package_or_packagelist, '3') }}
{% endmacro %}

{% macro pip2_install(package_or_packagelist) %}
{{ pip_install(package_or_packagelist, '2') }}
{% endmacro %}
