{% if pillar.get('http_proxy', '') != '' %}

  {% if salt['grains.get']('os_family') == "Debian" %}
/etc/apt/apt.conf.d/01proxy:
  file.managed:
    - contents: |
        Acquire::http::Proxy "{{ pillar.get('http_proxy') }}";
    - order: 5
  {% endif %}

/etc/profile.d/proxy.sh:
  file.managed:
    - makedirs: True
    - contents: |
        http_proxy="{{ pillar.get('http_proxy') }}"
        HTTP_PROXY="{{ pillar.get('http_proxy') }}"
        export http_proxy
        export HTTP_PROXY
    - order: 5

/etc/sudoers.d/proxy:
  file.managed:
    - makedirs: True
    - mode: "0440"
    - contents: |
        Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY NO_PROXY"
        Defaults env_keep += "http_proxy https_proxy ftp_proxy no_proxy"
    - order: 5
{% endif %}
