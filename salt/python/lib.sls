include:
  - python


{% macro pip_install(package, bin_env="") %}
python{{ postfix }}-{{ package }}:
  pip.installed:
    - name: {{ package }}
  {% if bin_env %}
    - bin_env: {{ binenv }}
  {% endif %}
    - require:
      - sls: python
{% endmacro %}

{% macro pip3_install(package) %}
{{ pip_install(package, '/usr/local/bin/pip3') }}
{% endmacro %}

{% macro pip2_install(package) %}
{{ pip_install(package, '/usr/local/bin/pip2') }}
{% endmacro %}
