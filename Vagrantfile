# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  config.vm.box = 'sputnik13/trusty64'
  config.vm.hostname = 'devstack'
  config.vm.network :private_network, ip: '192.168.50.8'

  config.vm.network :forwarded_port, guest: 80, host: 8880

  config.vm.synced_folder './shared/', '/home/vagrant/shared'
  config.vm.synced_folder './stack', '/opt/stack', type: 'nfs'

  if ENV['http_proxy'] != nil and ENV['https_proxy'] != nil and ENV['no_proxy'] != nil 
    if not Vagrant.has_plugin?('vagrant-proxyconf')
      system 'vagrant plugin install vagrant-proxyconf'
      raise 'vagrant-proxyconf was installed but it requires to execute again'
    end
    config.proxy.http     = ENV['http_proxy']
    config.proxy.https    = ENV['https_proxy']
    config.proxy.no_proxy = ENV['no_proxy']
  end

  config.vm.provider 'virtualbox' do |v|
    v.customize ['modifyvm', :id, '--memory', 1024 * 4 ]
  end

  config.vm.provider 'libvirt' do |v|
    v.memory = 1024 * 4
    v.nested = true
    v.cpu_mode = 'host-passthrough'
  end

  config.vm.provision 'shell' do |s|
    s.path = 'postinstall.sh'
    s.args = ['neutron']
  end

end
