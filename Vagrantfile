# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define :devstack do |devstack|
    devstack.vm.box      = 'precise64'
    devstack.vm.box_url  = 'http://files.vagrantup.com/precise64.box'
    devstack.vm.hostname = 'devstack-precise64'
    devstack.vm.network :private_network, ip: '192.168.50.11'
    devstack.vm.network :forwarded_port, guest: 80, host: 80
    devstack.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", 2048]
    end
    devstack.vm.provision "shell" do |s|
      s.path = "bootstrap.sh"
      s.args = ["ceilometer"]
    end
  end
end
