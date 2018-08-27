# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.8.4"
box = {
  :virtualbox => { :name => 'elastic/ubuntu-16.04-x86_64', :version => '20180708.0.0' },
  :libvirt => { :name => 'elastic/ubuntu-16.04-x86_64', :version=> '20180210.0.0'}
}

provider = (ENV['VAGRANT_DEFAULT_PROVIDER'] || :virtualbox).to_sym
puts "[INFO] Provider: #{provider} "

if ENV['no_proxy'] != nil or ENV['NO_PROXY']
  $no_proxy = ENV['NO_PROXY'] || ENV['no_proxy'] || "127.0.0.1,localhost"
  $subnet = "192.168.121"
  # NOTE: This range is based on vagrant-libivirt network definition
  (1..27).each do |i|
    $no_proxy += ",#{$subnet}.#{i}"
  end
end

Vagrant.configure("2") do |config|
  config.vm.hostname = 'devstack'
  config.vm.box = box[provider][:name]
  config.vm.box_version = box[provider][:version]

  if ENV['http_proxy'] != nil and ENV['https_proxy'] != nil
    if not Vagrant.has_plugin?('vagrant-proxyconf')
      system 'vagrant plugin install vagrant-proxyconf'
      raise 'vagrant-proxyconf was installed but it requires to execute again'
    end
    config.proxy.http     = ENV['http_proxy'] || ENV['HTTP_PROXY'] || ""
    config.proxy.https    = ENV['https_proxy'] || ENV['HTTPS_PROXY'] || ""
    config.proxy.no_proxy = $no_proxy
  end
  config.vm.provider 'libvirt' do |v|
    v.nested = true
    v.cpu_mode = 'host-passthrough'
    v.management_network_address = "192.168.121.0/27" # Management Network - This interface is used by OpenStack services and databases to communicate to each other.
  end
  [:virtualbox, :libvirt].each do |provider|
    config.vm.provider provider do |p, override|
      p.cpus = 2
      p.memory = 8192
    end
  end

  config.vm.synced_folder './shared/', '/home/vagrant/shared' , create: true
  config.vm.synced_folder './stack', '/opt/stack', create: true

  config.vm.provision 'shell' do |s|
    s.path = 'postinstall.sh'
    s.args = ['python-openstackclient']
    s.privileged = false
  end
end
