profile_packer:
  file.append:
    - name: /app/.profile
    - text: |
        export PACKER_CACHE_DIR=/tmp/packer_cache
