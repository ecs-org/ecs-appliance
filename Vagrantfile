# -*- mode: ruby -*-
# vi: set ft=ruby :

require "fileutils"
Vagrant.require_version ">= 1.6.0"

# Variables, can be overwritten by vagrant-include.rb
$cpus = 2
$memory = 4096
$server_name = File.basename(File.expand_path(File.dirname(__FILE__)))
$libvirt_management_network_name = "vagrant-libvirt"
$libvirt_management_network_address = nil
$libvirt_management_network_mac = nil
$libvirt_machine_virtual_size = 10
$clouddrive_path = File.join(File.dirname(__FILE__), 'seed.iso')

CUSTOM_CONFIG = File.join(File.dirname(__FILE__), "vagrant-include.rb")
if File.exist?(CUSTOM_CONFIG)
    require CUSTOM_CONFIG
end

Vagrant.configure(2) do |config|
    config.ssh.forward_agent = true
    config.vm.box = "xenial"
    config.vm.define "ecs-appliance"
    config.vm.synced_folder ".", "/app/appliance", type: "rsync", create: true, rsync__exclude: "", rsync__auto: false, rsync__args: ["--verbose", "--archive", "--delete", "-z", "--links"]

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
        lv.video_type = "vmvga"
        lv.volume_cache = "none"
        lv.machine_virtual_size = $libvirt_machine_virtual_size
        lv.management_network_name = $libvirt_management_network_name
        if $libvirt_management_network_address
            lv.management_network_address = $libvirt_management_network_address
        end
        if $libvirt_management_network_mac
            lv.management_network_mac = $libvirt_management_network_mac
        end
        if File.exist?($clouddrive_path)
            lv.storage :file, :device => :cdrom, :allow_existing => true, :path => $clouddrive_path
        end
    end

    config.vm.provider "virtualbox" do |vb, override|
        override.vm.box_url = "http://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-vagrant.box"
        vb.memory = $memory
        vb.cpus = $cpus
        if File.exist?($clouddrive_path)
            vb.customize [
                "storageattach", :id,
                "--storagectl", "SCSI",
                "--port", "1",
                "--type", "dvddrive",
                "--medium", $clouddrive_path
            ]
        end
        # see https://github.com/tomkins/cloud-init-vagrant/blob/master/Vagrantfile
        vb.customize [
            "modifyvm", :id,
            "--uartmode1", "disconnected"
        ]
    end

    config.vm.provision "shell", privileged:true, inline: <<-SHELL
        # https://github.com/mitchellh/vagrant/issues/5673
        hostnamectl set-hostname #{$server_name}
    SHELL

    config.vm.provision :salt do |salt|
        salt.masterless = true
        salt.minion_config = "salt/minion"
        salt.run_highstate = true
        salt.log_level = "info"
        # https://github.com/mitchellh/vagrant/issues/3754
        salt.verbose = true
        #salt.install_type = "git"
        #salt.install_args = "v2015.5.1"
        #salt.bootstrap_options = "-F -c /tmp/ -P"
        salt.pillar({
            "appliance" => {
                "enabled" => true
            }
        })
    end

end
