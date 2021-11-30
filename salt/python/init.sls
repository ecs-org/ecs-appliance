python:
  pkg.installed:
    - pkgs:
      - python
      - python-setuptools
      - python-pip
      - python-pip-whl
      - python3
      - python3-pip
      - python3-setuptools
      - python3-venv

{# XXX pip and virtualenv is broken on xenial, update from pypi #}
{# https://github.com/pypa/pip/issues/3282 #}

pip2-upgrade:
  cmd.run:
    - name: pip2 install -U pip virtualenv
    - onlyif: test "$(which pip2)" = "/usr/bin/pip2"

pip3-upgrade:
  cmd.run:
    - name: pip3 install -U pip
    - onlyif: test "$(which pip3)" = "/usr/bin/pip3"

virtualenv3-upgrade:
  cmd.run:
    - name: /usr/local/bin/pip3 -U virtualenv
    - onlyif: test "$(which virtualenv)" = "/usr/bin/virtualenv"
    - require:
      - cmd: pip3-upgrade

{% macro pip_install(package_or_packagelist, version="") %}
"python{{ version }}-{{ package_or_packagelist }}":
  pip.installed:
  {%- if package_or_packagelist is iterable and package_or_packagelist is not string %}
    - pkgs: {{ package_or_packagelist}}
  {%- else %}
    - name: {{ package_or_packagelist }}
  {%- endif %}
  {%- if version %}
    - bin_env: {{ '/usr/local/bin/pip'+ version }}
  {%- endif %}
    - require:
      - pkg: python
      - cmd: pip2-upgrade
      - cmd: pip3-upgrade
  {%- if kwargs is defined %}
    {%- if salt['grains.get']('pythonversion','')[0] == '3' %}
      {%- for k,d in kwargs.items() %}
    - {{ k }}: {{ d }}
      {%- endfor %}
    {%- else %}
      {%- for k,d in kwargs.iteritems() %}
    - {{ k }}: {{ d }}
      {%- endfor %}
    {%- endif %}
  {%- endif %}
{% endmacro %}

{% macro pip3_install(package_or_packagelist) %}
{{ pip_install(package_or_packagelist, '3') }}
{% endmacro %}

{% macro pip2_install(package_or_packagelist) %}
{{ pip_install(package_or_packagelist, '2') }}
{% endmacro %}
