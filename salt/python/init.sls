python:
  pkg.installed:
    - pkgs:
      - python
      - python3
{# refresh old "faulty" pip with version from pypi, as workaround for saltstack and probably others #}

remove_faulty_pip:
  pkg.removed:
    - pkgs:
      - python-pip
      - python-pip-whl
    - require:
      - pkg: python

{% for i in ['', '3'] %}

easy_install{{ i }}_pip:
  cmd.run:
    - name: easy_install{{ i }} pip
    - unless: which pip{{ i }}
    - require:
      - pkg: remove_faulty_pip
{#  - reload_modules: true #}

{% endfor %}
