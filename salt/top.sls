base:
  '*':
    - http_proxy
    - virtual-tools
    - hardware-tools
    - ssh
    - python
    - common

  'appliance:enabled:true':
    - match: pillar
    - appliance

  'builder:enabled:true':
    - match: pillar
    - builder
