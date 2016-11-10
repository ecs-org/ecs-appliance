env_gen_pkgs:
  pkg.installed:
    - pkgs:
      - gnupg
      - openssl
      
{{ salt['pillar.get']('targetdir') }}/env.yml:
  file.managed:
    - template: jinja
    - source: salt://common/env.template.yml
    - user: {{ salt['pillar.get']('user') }}
    - mode: "0600"
    - makedirs: true
    - defaults:
        domain: {{ salt['pillar.get']('domain') }}
