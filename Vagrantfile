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
$devstack_distro = ENV['DEVSTACK_DISTRO'] || "ubuntu"
$devstack_distro_release = ENV['DEVSTACK_DISTRO_RELEASE'] || "bionic"

Vagrant.configure("2") do |config|
  config.vm.provider :libvirt
  config.vm.provider :virtualbox

  config.vm.hostname = 'devstack'
  config.vm.box = $vagrant_boxes[$devstack_distro][$devstack_distro_release]["name"]
  config.vm.box_version = $vagrant_boxes[$devstack_distro][$devstack_distro_release]["version"]

  if ENV['http_proxy'] != nil and ENV['https_proxy'] != nil
    if not Vagrant.has_plugin?('vagrant-proxyconf')
      system 'vagrant plugin install vagrant-proxyconf'
      raise 'vagrant-proxyconf was installed but it requires to execute again'
    end
    config.proxy.http     = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ""
    config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ""
    config.proxy.no_proxy = $no_proxy
  end
  config.vm.provider :libvirt do |v|
    v.nested = true
    v.random_hostname = true
    v.management_network_address = "192.168.121.0/24"
  end
  [:virtualbox, :libvirt].each do |provider|
    config.vm.provider provider do |p, override|
      p.cpus = 2
      p.memory = 8192
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
