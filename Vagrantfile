# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'fileutils'
Vagrant.require_version ">= 1.6.0"

$cpus = 2
$memory = 1500
$server_name = File.expand_path(File.dirname(__FILE__)).split('/').last

Vagrant.configure(2) do |config|

  config.ssh.forward_agent = true
  config.vm.box = "xenial"
  config.vm.define "ecs-builder"
  config.vm.synced_folder ".", "/app", type: "rsync", create: true, rsync__exclude: "", rsync__auto: false

  if Vagrant.has_plugin?("vagrant-proxyconf")
    if "#{ENV['http_proxy']}" != ""
      config.proxy.http  = "#{ENV['http_proxy']}"
    end
  end

  config.vm.provider "libvirt" do |lv, override|
    lv.memory = $memory
    lv.cpus = $cpus
    lv.disk_bus = "virtio"
    lv.nic_model_type = "virtio"
    lv.video_type = 'vmvga'
    lv.volume_cache = 'none'
  end

  config.vm.provider "virtualbox" do |vb, override|
    vb.memory = $memory
    vb.cpus = $cpus
    override.vm.box_url = "http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-vagrant.box"
  end

  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = "minion"
    salt.run_highstate = true
    salt.log_level = "info"
    #salt.install_type = "git"
    #salt.install_args = "v2015.5.1"
  end

end
