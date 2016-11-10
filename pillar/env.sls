{% if salt['cmd.retcode']('test -e /app/active-env.yml') == 0 %}
include:
  - custom-env
{% else %}
include:
  - default-env
{% endif %}

{% import_yaml "default-env.sls" as default_env %}
