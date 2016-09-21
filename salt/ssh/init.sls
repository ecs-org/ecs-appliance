openssh-client:
  pkg:
    - installed

openssh-server:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - name: ssh
    - require:
      - pkg: openssh-server

/etc/ssh/sshd_config:
  file.append:
    - text: "UseDNS no"
    - watch_in:
      - service: openssh-server

{% from "ssh/lib.sls" import ssh_keys_update %}

{{ ssh_keys_update('root',
    pillar['adminkeys_present']|d(False),
    pillar['adminkeys_absent']|d(False)
    )
}}
