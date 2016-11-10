
{% set domain = salt['pillar.get']('domain') %}
{% set targetdir = salt['pillar.get']('targetdir') %}
{% set env_default = salt['pillar.get']('default_env', {}) %}


{% macro ssl_secret(len=39) -%}
{{ salt['cmd.run_stdout']('openssl rand -base64 39') }}
{%- endmacro %}

{% macro gpg_secret(ownername) -%}
{%- set batch = 'Key-Type: 1\nKey-Length: 2048\nExpire-Date: 0\n'+
    'Name-Real: '+ ownername+ '\n%secring -&1\n%pubring -&2\n%commit\n' %}
{%- set gpg_call = 'gpg --quiet --no-default-keyring --batch --yes --armor --gen-key' %}
{{ salt['cmd.run_stdout'](gpg_call, stdin=batch) }}
{%- endmacro %}


{% load_yaml as env_overwrite %}
appliance:
  domain: {{ domain }}
  allowed_hosts: {{ domain }}
  ssl:
    letsencrypt:
      enabled: true
    client_certs_mandatory: true
  authorized_keys: |
      # put your ssh keys here, this is a text block not a list like cloud-init ssh_authorized_keys
  backup:
    url: ssh://app@localhost/volatile/ecs-backup-test/
    encrypt: |
{{ gpg_secret('ecs_backup')|indent(8,True) }}

ecs:
  userswitcher:
      enabled: false
  settings: |
      DOMAIN = '{{ domain }}'
      ABSOLUTE_URL_PREFIX = 'https://{}'.format(DOMAIN)
      ALLOWED_HOSTS = [DOMAIN, ]
      SECURE_PROXY_SSL = True
      CLIENT_CERTS_REQUIRED = True
      DEBUG = False

      ETHICS_COMMISSION_UUID = 'ecececececececececececececececec'
      SECRET_KEY = '{{ ssl_secret }}'
      REGISTRATION_SECRET = '{{ ssl_secret }}'
      PASSWORD_RESET_SECRET = '{{ ssl_secret }}'

      EMAIL_BACKEND = 'django.core.mail.backends.console.emailbackend'
      EMAIL_BACKEND_UNFILTERED = 'django.core.mail.backends.console.EmailBackend'

  vault_encrypt: |
{{ gpg_secret('ecs_mediaserver')|indent(6,True) }}

  vault_sign: |
{{ gpg_secret('ecs_authority')|indent(6,True) }}

{% endload %}


{% set env_new=salt['grains.filter_by']({'default': env_default},
  grain='default', default= 'default', merge= env_overwrite) %}


{{ targetdir }}/env.yml:
  file.managed:
    - contents: |
{{ env_new|yaml(False)|indent(8,True) }}
