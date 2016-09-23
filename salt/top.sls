base:
  '*':
    - http_proxy
    - guest-tools
    - ssh
    - python
    - common
    - extra

  'appliance:enabled:true':
    - match: pillar
    - appliance

  'builder:enabled:true':
    - match: pillar
    - builder
