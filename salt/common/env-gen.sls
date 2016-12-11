include:
  - qrcode

env_gen_pkgs:
  pkg.installed:
    - pkgs:
      - gnupg
      - openssl
      - enscript
      - ghostscript
      - pdftk
      - swaks

{{ salt['pillar.get']('targetdir') }}/env.yml:
  file.managed:
    - template: jinja
    - source: {{ salt['pillar.get']('template') }}
    - user: {{ salt['pillar.get']('appuser') }}
    - mode: "0600"
    - makedirs: true
    - defaults:
        domain: {{ salt['pillar.get']('domain') }}
    - require:
      - sls: qrcode
      - pkg: env_gen_pkgs
