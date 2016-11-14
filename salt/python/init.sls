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

pip_upgrade:
  cmd.run:
    - name: pip install --upgrade pip

pip3_upgrade:
  cmd.run:
    - name: pip3 install --upgrade pip
