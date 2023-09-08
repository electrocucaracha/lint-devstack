# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c) 2020, 2023
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

def which(cmd)
  exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
  ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    end
  end
  nil
end

require "yaml"
vagrant_boxes = YAML.load_file("#{File.dirname(__FILE__)}/distros_supported.yml")
config_file = "#{File.dirname(__FILE__)}/vm_config.yml"
config_file = "#{File.dirname(__FILE__)}/override_config.yml" if File.exist?("#{File.dirname(__FILE__)}/override_config.yml")
vm_config = YAML.load_file(config_file)

no_proxy = ENV["NO_PROXY"] || ENV["no_proxy"] || "127.0.0.1,localhost"
(1..254).each do |i|
  no_proxy += ",10.0.2.#{i}"
end

public_nic = `ip r get 1.1.1.1 | awk 'NR==1{print $5}'`.strip! || "eno1"
public_cidr = `ip r | grep "dev $(ip r get 1.1.1.1 | awk 'NR==1{print $5}') .* scope link" | awk '{print $1}'`.strip! || "192.168.0.0/24"
public_gw = `ip r | grep "^default" | awk 'NR==1{print $3}'`.strip! || "192.168.0.1"
vb_public_nic = `VBoxManage list bridgedifs | grep "^Name:.*#{public_nic}" | awk -F "Name:[ ]*" '{ print $2}'`.strip! if which "VBoxManage"

qemu_version = ""
qemu_version = `qemu-system-x86_64 --version | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/'` if which "qemu-system-x86_64"
sriov_devices = ""
qat_devices = ""
if which "lspci"
  sriov_devices = `lspci | grep "Ethernet .* Virtual Function"|awk '{print $1}'`
  qat_devices = `for i in 0434 0435 37c8 6f54 19e2; do lspci -d 8086:$i -m; done|awk '{print $1}'`
end

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.hostname = vm_config["name"]
  config.vm.box = vagrant_boxes[vm_config["os"]["name"]][vm_config["os"]["release"]]["name"]
  config.vm.box_version = vagrant_boxes[vm_config["os"]["name"]][vm_config["os"]["release"]]["version"] if vagrant_boxes[vm_config["os"]["name"]][vm_config["os"]["release"]].key? "version"
  config.vm.box_check_update = false

  config.vm.synced_folder "./", "/vagrant", SharedFoldersEnableSymlinksCreate: false
  config.vm.synced_folder "./stack", "/opt/stack", create: true
  config.vm.synced_folder "./post-configs", "/home/vagrant/post-configs", create: true

  # Public - Provides external access to OpenStack services. For
  # instances, it provides the route out to the external network and
  # the IP addresses to enable inbound connections to the instances.
  # This network can also provide the public API endpoints to
  # connect to OpenStack services.
  config.vm.network :public_network, dev: public_nic, bridge: vb_public_nic, auto_config: false

  if !ENV["http_proxy"].nil? && !ENV["https_proxy"].nil?
    unless Vagrant.has_plugin?("vagrant-proxyconf")
      system "vagrant plugin install vagrant-proxyconf"
      raise "vagrant-proxyconf was installed but it requires to execute again"
    end
    config.proxy.http     = ENV["http_proxy"] || ENV["HTTP_PROXY"] || ""
    config.proxy.https    = ENV["https_proxy"] || ENV["HTTPS_PROXY"] || ""
    config.proxy.no_proxy = no_proxy
  end
  %i[virtualbox libvirt].each do |provider|
    config.vm.provider provider do |p|
      p.cpus = vm_config["cpus"]
      p.memory = vm_config["memory"]
    end
  end

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.customize ["modifyvm", :id, "--nictype1", "virtio", "--cableconnected1", "on"]
    # https://bugs.launchpad.net/cloud-images/+bug/1829625/comments/2
    v.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    v.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
    # Enable nested paging for memory management in hardware
    v.customize ["modifyvm", :id, "--nestedpaging", "on"]
    # Use large pages to reduce Translation Lookaside Buffers usage
    v.customize ["modifyvm", :id, "--largepages", "on"]
    # Use virtual processor identifiers  to accelerate context switching
    v.customize ["modifyvm", :id, "--vtxvpid", "on"]
  end

  config.vm.provider :libvirt do |v, override|
    override.vm.synced_folder "./", "/vagrant", SharedFoldersEnableSymlinksCreate: false, type: "nfs",
                                                nfs_version: ENV.fetch("VAGRANT_NFS_VERSION", 3)
    override.vm.synced_folder "./stack", "/opt/stack", create: true, type: "nfs",
                                                       nfs_version: ENV.fetch("VAGRANT_NFS_VERSION", 3)
    override.vm.synced_folder "./post-configs", "/home/vagrant/post-configs", create: true, type: "nfs",
                                                                              nfs_version: ENV.fetch("VAGRANT_NFS_VERSION", 3)
    v.nested = true
    v.random_hostname = true

    v.management_network_address = "10.0.2.0/24"
    v.management_network_name = "administration"

    # Intel Corporation Persistent Memory
    if Gem::Version.new(qemu_version) > Gem::Version.new("2.6.0") && (vm_config.key? "pmem")
      v.qemuargs value: "-machine"
      v.qemuargs value: "pc,accel=kvm,nvdimm=on"
      v.qemuargs value: "-m"
      v.qemuargs value: "#{vm_config['pmem']['size']},slots=#{vm_config['pmem']['slots']},maxmem=#{vm_config['pmem']['max_size']}"
      vm_config["pmem"]["vNVDIMMs"].each do |vnvdimm|
        v.qemuargs value: "-object"
        v.qemuargs value: "memory-backend-file,id=#{vnvdimm['mem_id']},share=#{vnvdimm['share']},mem-path=#{vnvdimm['path']},size=#{vnvdimm['size']}"
        v.qemuargs value: "-device"
        v.qemuargs value: "nvdimm,id=#{vnvdimm['id']},memdev=#{vnvdimm['mem_id']},label-size=2M"
      end
    end

    # Non-Uniform Memory Access (NUMA)
    if vm_config.key? "numa_nodes"
      numa_nodes = []
      vm_config["numa_nodes"].each do |numa_node|
        numa_node["cpus"].strip!
        numa_nodes << { cpus: numa_node["cpus"], memory: (numa_node["memory"]).to_s }
      end
      v.numa_nodes = numa_nodes
    end

    # "Physicalisation" of virtualisation

    # Intel Corporation QuickAssist Technology
    if vm_config.key? "qat_dev"
      vm_config["qat_dev"].each do |dev|
        next unless qat_devices.include? dev.to_s

        bus = dev.split(":")[0]
        slot = dev.split(":")[1].split(".")[0]
        function = dev.split(":")[1].split(".")[1]
        v.pci bus: "0x#{bus}", slot: "0x#{slot}", function: "0x#{function}"
      end
    end

    # Single Root I/O Virtualization (SR-IOV)
    if vm_config.key? "sriov_dev"
      vm_config["sriov_dev"].each do |dev|
        next unless sriov_devices.include? dev.to_s

        bus = dev.split(":")[0]
        slot = dev.split(":")[1].split(".")[0]
        function = dev.split(":")[1].split(".")[1]
        v.pci bus: "0x#{bus}", slot: "0x#{slot}", function: "0x#{function}"
      end
    end
  end

  config.vm.provision "shell", privileged: false do |sh|
    sh.env = {
      DEBUG: "true",
      OS_DISABLE_SVC_LIST: "tempest",
      OS_PROJECT_LIST: "octavia",
      # Range not used on the local network
      LINT_DEVSTACK_FLOATING_RANGE: ENV.fetch("FLOATING_RANGE", public_cidr.to_s),
      # Server would normally use to get off the network
      LINT_DEVSTACK_PUBLIC_NETWORK_GATEWAY: ENV.fetch("PUBLIC_NETWORK_GATEWAY", public_gw.to_s),
      LINT_DEVSTACK_PUBLIC_INTERFACE: "eth1",
      # Internal address space used by the instances
      LINT_DEVSTACK_FIXED_RANGE: ENV.fetch("FIXED_RANGE", "10.11.12.0/24")
    }
    sh.inline = <<-SHELL
      set -o errexit
      set -o pipefail

      cd /vagrant
      ./setup.sh | tee ~/setup.log
    SHELL
  end
end
