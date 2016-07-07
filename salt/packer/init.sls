{% set version="0.10.1" %}
{% set source_hash="7d51fc5db19d02bbf32278a8116830fae33a3f9bd4440a58d23ad7c863e92e28" %}

packer:
  pkg.installed:
    - pkgs:
      - qemu-utils
      - qemu-kvm
  file.directory:
    - name: /usr/local/share/packer-v{{ version }}-linux-amd64
    - makedirs: true
  archive.extracted:
    - name: /usr/local/share/packer-v{{ version }}-linux-amd64
    - source: https://releases.hashicorp.com/packer/{{ version }}/packer_{{ version }}_linux_amd64.zip
    - source_hash: sha256={{ source_hash }}
    - archive_format: zip
    - if_missing: /usr/local/share/packer-v{{ version }}-linux-amd64/packer
    - require:
      - file: packer
  cmd.run:
    - name: |
        for n in `ls /usr/local/share/packer-v{{ version }}-linux-amd64`; do
            chmod +x /usr/local/share/packer-v{{ version }}-linux-amd64/$n
            ln -s -f -T /usr/local/share/packer-v{{ version }}-linux-amd64/$n /usr/local/bin/$n
        done
    - require:
      - archive: packer
