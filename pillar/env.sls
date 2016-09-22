{% if salt['cmd.retcode']('test -e /app/env.yml') == 0 %}
include:
  - custom-env
{% else %}
include:
  - default-env
{% endif %}
