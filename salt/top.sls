base:
  '*':
    - http_proxy
    - virtual-tools
    - hardware-tools
    - kernel
    - ssh
    - python
    - common

  'appliance:enabled:true':
    - match: pillar
    - appliance

  'builder:enabled:true':
    - match: pillar
    - builder
