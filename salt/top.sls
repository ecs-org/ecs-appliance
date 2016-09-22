base:
  '*':
    - http_proxy
    - python
    - common
    - user
    - guest-tools
    - ssh
    - extra

  'appliance:enabled:true':
    - match: pillar
    - appliance

  'builder:enabled:true':
    - match: pillar
    - builder
