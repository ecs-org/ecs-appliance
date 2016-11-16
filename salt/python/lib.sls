include:
  - python


{% macro pip_install(package, version="") %}
python{{ version }}-{{ package }}:
  pip.installed:
    - name: {{ package }}
  {% if version %}
    - bin_env: {{ '/usr/local/bin/pip'+ version }}
  {% endif %}
    - require:
      - sls: python
{% endmacro %}

{% macro pip3_install(package) %}
{{ pip_install(package, '3') }}
{% endmacro %}

{% macro pip2_install(package) %}
{{ pip_install(package, '2') }}
{% endmacro %}
