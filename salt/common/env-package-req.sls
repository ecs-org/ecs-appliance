include:
  - qrcode

env_build_pkgs:
  pkg.installed:
    - pkgs:
      - gnupg
      - openssl
      - enscript
      - ghostscript
      - pdftk
      - swaks

flatyaml_install:
  pkg.installed:
    - pkgs:
      - python3-yaml
  file.managed:
    - name: /usr/local/bin/flatyaml.py
    - source: salt://common/flatyaml.py
    - mode: "0755"
