# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  'vagrant_box'     => 'ubuntu/trusty64',
  'hostname'        => 'config',
}

vd_conf = ENV.fetch('VD_CONF', 'etc/settings.yaml')
if File.exist?(vd_conf)
  require 'yaml'
  user_conf = YAML.load_file(vd_conf)
  conf.update(user_conf)
end

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder "stack/", "/opt/stack", create: true
  config.vm.box      = conf['vagrant_box']
  config.vm.hostname = 'devstack'
  config.vm.network :private_network, ip: '192.168.50.8'
  config.vm.network :forwarded_port, guest: 5672 , host: 5672
  config.vm.network :forwarded_port, guest: 3306, host: 3306
  config.vm.network :forwarded_port, guest: 27017, host: 27017
  config.vm.network :forwarded_port, guest: 5000, host: 5000
  config.vm.network :forwarded_port, guest: 35357, host: 35357
  config.vm.network :forwarded_port, guest: 9292, host: 9292
  config.vm.network :forwarded_port, guest: 8774, host: 8774
  config.vm.network :forwarded_port, guest: 8776, host: 8776
  config.vm.network :forwarded_port, guest: 8777, host: 8777
  config.vm.network :forwarded_port, guest: 8080, host: 8080
  config.vm.network :forwarded_port, guest: 80, host: 8880
  config.vm.network :forwarded_port, guest: 6080, host: 6080
  config.vm.provider "virtualbox" do |v|
    v.customize ["modifyvm", :id, "--memory", 1024 * 4 ]
  end
  config.vm.provision "shell" do |s|
    s.path = "post-install.sh"
    s.args = ["ceilometer"]
  end
end
