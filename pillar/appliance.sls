appliance:

docker:
  ip: "172.17.0.1"
  net: "172.17.0.0/16"
  netmask: "255.255.0.0"
  options: --storage-driver=overlay2 --bridge=docker0
