{% if salt['cmd.retcode']('test -e /run/active-env.yml') == 0 %}
include:
  - custom-env
{% else %}
include:
  - default-env
{% endif %}
