


{{ targetdir }}/env.yml:
  file.managed:
    - template: jinja
    - source: salt://common/env.template.yml
    - context:
        domain: {{ domain }}
        targetdir: {{ targetdir }}

    - contents: |
{{ env_new|yaml(False)|indent(8,True) }}
