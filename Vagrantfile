# -*- mode: ruby -*-
# vi: set ft=ruby :
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

$no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || "127.0.0.1,localhost"
# NOTE: This range is based on vagrant-libvirt network definition CIDR 192.168.121.0/24
(1..254).each do |i|
  $no_proxy += ",192.168.121.#{i}"
end
$no_proxy += ",10.0.2.15"
$socks_proxy = ENV['socks_proxy'] || ENV['SOCKS_PROXY'] || ""

File.exists?("/usr/share/qemu/OVMF.fd") ? loader = "/usr/share/qemu/OVMF.fd" : loader = File.join(File.dirname(__FILE__), "OVMF.fd")
if not File.exists?(loader)
  system('curl -O https://download.clearlinux.org/image/OVMF.fd')
end

$vagrant_boxes = YAML.load_file(File.dirname(__FILE__) + '/distros_supported.yml')
$vm_config = YAML.load_file(File.dirname(__FILE__) + '/vm_config.yml')
$qemu_version = `qemu-system-x86_64 --version | perl -pe '($_)=/([0-9]+([.][0-9]+)+)/'`
$sriov_devices = `lspci | grep "Ethernet .* Virtual Function"|awk '{print $1}'`
$qat_devices = `for i in 0434 0435 37c8 6f54 19e2; do lspci -d 8086:$i -m; done|awk '{print $1}'`

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.hostname = $vm_config["name"]
  config.vm.box = $vagrant_boxes[$vm_config["os"]["name"]][$vm_config["os"]["release"]]["name"]
  config.vm.box_version = $vagrant_boxes[$vm_config["os"]["name"]][$vm_config["os"]["release"]]["version"]

  if ENV['http_proxy'] != nil and ENV['https_proxy'] != nil
    if not Vagrant.has_plugin?('vagrant-proxyconf')
      system 'vagrant plugin install vagrant-proxyconf'
      raise 'vagrant-proxyconf was installed but it requires to execute again'
    end
    config.proxy.http     = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ""
    config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ""
    config.proxy.no_proxy = $no_proxy
  end
  [:virtualbox, :libvirt].each do |provider|
    config.vm.provider provider do |p, override|
      p.cpus = $vm_config["cpus"]
      p.memory = $vm_config["memory"]
    end
  end

  config.vm.provider :libvirt do |v|
    v.nested = true
    v.random_hostname = true
    v.management_network_address = "192.168.121.0/24"

    # Intel Corporation Persistent Memory
    if Gem::Version.new($qemu_version) > Gem::Version.new('2.6.0')
      if $vm_config.has_key? "pmem"
        v.qemuargs :value => '-machine'
        v.qemuargs :value => 'pc,accel=kvm,nvdimm=on'
        v.qemuargs :value => '-m'
        v.qemuargs :value => "#{$vm_config['pmem']['size']},slots=#{$vm_config['pmem']['slots']},maxmem=#{$vm_config['pmem']['max_size']}"
        $vm_config['pmem']['vNVDIMMs'].each do |vNVDIMM|
          v.qemuargs :value => '-object'
          v.qemuargs :value => "memory-backend-file,id=#{vNVDIMM['mem_id']},share=#{vNVDIMM['share']},mem-path=#{vNVDIMM['path']},size=#{vNVDIMM['size']}"
          v.qemuargs :value => '-device'
          v.qemuargs :value => "nvdimm,id=#{vNVDIMM['id']},memdev=#{vNVDIMM['mem_id']},label-size=2M"
        end
      end
    end

    # Non-Uniform Memory Access (NUMA)
    if $vm_config.has_key? "numa_nodes"
      $numa_nodes = []
      $vm_config['numa_nodes'].each do |numa_node|
        numa_node['cpus'].strip!
        $numa_nodes << {:cpus=>numa_node['cpus'], :memory=>"#{numa_node['memory']}"}
      end
      v.numa_nodes = $numa_nodes
    end

    # "Physicalisation" of virtualisation

    # Intel Corporation QuickAssist Technology
    if $vm_config.has_key? "qat_dev"
      $vm_config['qat_dev'].each do |dev|
        if $qat_devices.include? dev.to_s
          bus=dev.split(':')[0]
          slot=dev.split(':')[1].split('.')[0]
          function=dev.split(':')[1].split('.')[1]
          v.pci :bus => "0x#{bus}", :slot => "0x#{slot}", :function => "0x#{function}"
        end
      end
    end

    # Single Root I/O Virtualization (SR-IOV)
    if $vm_config.has_key? "sriov_dev"
      $vm_config['sriov_dev'].each do |dev|
        if $sriov_devices.include? dev.to_s
          bus=dev.split(':')[0]
          slot=dev.split(':')[1].split('.')[0]
          function=dev.split(':')[1].split('.')[1]
          v.pci :bus => "0x#{bus}", :slot => "0x#{slot}", :function => "0x#{function}"
        end
      end
    end
  end

  config.vm.synced_folder './', '/vagrant'
  config.vm.synced_folder './stack', '/opt/stack', create: true
  config.vm.synced_folder './post-configs', '/home/vagrant/post-configs', create: true

  config.vm.provision 'shell', privileged: false do |sh|
    sh.inline = <<-SHELL
      cd /vagrant
      ./setup.sh python-openstackclient | tee ~/setup.log
    SHELL
  end
end
