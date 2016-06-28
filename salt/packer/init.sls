packer:
  pkg.installed:
    - pkgs:
      - qemu-utils
      - qemu-kvm

profile_packer_settings:
  file.append:
    - name: /home/{{ s.user }}/.profile
    - text: |
        export PACKER_CACHE_DIR={{ s.image_base }}/tmp/packer_cache

{% set version="0.10.0" %}
{% set source_hash="eadd33bc0f8fa42034059fc1cda5f43ed6f540746e767480f0706ebed49b45e5" %}

packer_binary:
  file.directory:
    - name: /usr/local/src/packer-v{{ version }}-linux-amd64
    - makedirs: true
  archive.extracted:
    - name: /usr/local/src/packer-v{{ version }}-linux-amd64
    - source: https://releases.hashicorp.com/packer/{{ version }}/packer_{{ version }}_linux_amd64.zip
    - source_hash: sha256={{ source_hash }}
    - archive_format: zip
    - if_missing: /usr/local/src/packer-v{{ version }}-linux-amd64/packer
    - require:
      - file: packer_binary
  cmd.run:
    - name: |
        for n in `ls /usr/local/src/packer-v{{ version }}-linux-amd64`; do
            chmod +x /usr/local/src/packer-v{{ version }}-linux-amd64/$n
            ln -s -f -T /usr/local/src/packer-v{{ version }}-linux-amd64/$n /usr/local/bin/$n
        done
    - require:
      - archive: packer_binary
