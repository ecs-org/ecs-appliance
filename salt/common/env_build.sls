
{{ targetdir }}/meta-data:
  file.managed:
    - contents: |
      instance-id: iid-cloud-default
      local-hostname: linux

{{ targetdir }}/cloud-init-cidata.iso:
  cmd.run:
    - name: genisoimage -volid cidata -joliet -rock -input-charset utf-8 -output {{ targetdir }}/cloud-init-cidata.iso -graft-points user-data={{ targetdir }}/env.yml meta-data={{ targetdir }}/meta-data
