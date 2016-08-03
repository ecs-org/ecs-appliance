base:
  '*':
    - http_proxy
    - common
    - guest-tools
    - ssh
    - extra

  'appliance:enabled:true':
    - match: pillar
    - appliance

  'builder:enabled:true':
    - match: pillar
    - builder
