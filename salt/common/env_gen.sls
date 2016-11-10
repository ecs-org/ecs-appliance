{{ salt['pillar.get']('targetdir') }}/env.yml:
  file.managed:
    - template: jinja
    - source: salt://common/env.template.yml
    - defaults:
        domain: {{ salt['pillar.get']('domain') }}
        targetdir: {{ salt['pillar.get']('targetdir') }}
