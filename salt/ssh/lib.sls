{% macro ssh_keys_update(user, adminkeys_present, adminkeys_absent) %}

  {% if adminkeys_present|d(False) %}
{{ user }}_adminkeys_present:
  ssh_auth.present:
    - user: {{ user }}
    - names:
    {%- for adminkey in adminkeys_present %}
      - "{{ adminkey }}"
    {% endfor %}
  {% endif %}

  {% if adminkeys_absent|d(False) %}
{{ user }}_adminkeys_absent:
  ssh_auth.absent:
    - user: {{ user }}
    - names:
    {%- for adminkey in adminkeys_absent %}
      - "{{adminkey}}"
    {% endfor %}
  {% endif %}

{% endmacro %}

{% macro remove_login_as_user_keys(user) %}
{{ user }}_remove_keys_with_options:
  file.replace:
    - name: {{ salt['user.info'](user).home }}/.ssh/authorized_keys
    - pattern: |
        no.+,no.+,no.+,command=.echo..Please login as the user.+rather than the user.+;echo;sleep 10..
    - repl: ""

{% endmacro %}
