{% from "kernel/defaults.jinja" import settings as kernel with context %}

{%- set selected= kernel.select|d('default') %}
{%- if grains['virtual'] == 'physical' %}
  {%- set flavor='physical' %}
{%- else %}
  {%- set flavor='virtual' %}
{%- endif %}

{%- if grains['virtual']|upper in ['LXC', 'SYSTEMD-NSPAWN', 'NSPAWN'] %}
linux-image:
  pkg.installed:
    - pkgs:
      - {{ kernel.default.virtual.tools }}

{%- else %}
  {%- set release_running= salt['grains.get']('kernelrelease') %}
  {%- set dpkg_retcode= salt['cmd.retcode'](
    'dpkg -s "'+ kernel[selected][flavor].kernel+ '"', ignore_retcode=true)
  %}
  {%- set is_installed_requested= true if dpkg_retcode == 0 else false %}
  {%- if is_installed_requested %}
    {%- set release_requested= salt['cmd.run_stdout'](
    'apt-cache depends "'+ kernel[selected][flavor].kernel+ '"'+
    ' | grep -i "depends: linux-image-"'+
    ' | sed -r "s/[^:]+: linux-image-(.+)$/\\1/g"', python_shell=true)
    %}
  {%- else %}
    {%- set release_requested= 'uninstalled' %}
  {%- endif %}

linux-image:
  pkg.installed:
    - pkgs:
      - {{ kernel[selected][flavor].base }}
      - {{ kernel[selected][flavor].kernel }}
      - {{ kernel[selected][flavor].tools }}
      - {{ kernel[selected][flavor].headers }}
  {%- if (not is_installed_requested) or (release_running != release_requested) %}
  cmd.run:
    - name: update-grub
  file.touch:
    - name: /run/reboot-required
    - onchanges:
      - pkg: linux-image
  {%- endif %}

  {%- for choice in kernel.available %}
    {%- if choice != selected %}
      {%- set is_installed_old= salt['pkg.info_installed'](
        kernel[choice][flavor].base,
        kernel[choice][flavor].kernel,
        kernel[choice][flavor].tools,
        kernel[choice][flavor].headers,
        failhard=false)
      %}
remove-linux-image-{{ choice }}:
  pkg.removed:
    - pkgs:
      - {{ kernel[choice][flavor].base }}
      - {{ kernel[choice][flavor].kernel }}
      - {{ kernel[choice][flavor].tools }}
      - {{ kernel[choice][flavor].headers }}

      {%- if is_installed_old %}
remove-linux-image-autoremove-{{ choice }}:
  cmd.run:
    - env:
      - DEBIAN_FRONTEND: noninteractive
    - name: apt-get -y autoremove
    - require:
      - pkg: remove-linux-image-{{ choice }}
remove-linux-image-update-grub-{{ choice }}:
  cmd.run:
    - name: update-grub
    - require:
      - cmd: remove-linux-image-autoremove-{{ choice }}
      {%- endif %}
    {%- endif %}
  {%- endfor %}
{%- endif %}
