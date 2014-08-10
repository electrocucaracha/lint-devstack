# -*- mode: ruby -*-
# vi: set ft=ruby :

conf = {
  'vagrant_box'    => 'precise64',
  'vagrant_box_ur' => 'http://files.vagrantup.com/precise64.box',
  'hostname'       => 'devstack-precise64',
  'ip_address'     => '192.168.50.11',
  'memory'         => '1024',
}

vd_conf = ENV.fetch('VD_CONF', 'etc/settings.yaml')
if File.exist?(vd_conf)
  require 'yaml'
  user_conf = YAML.load_file(vd_conf)
  conf.update(user_conf)
end

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.define :devstack do |devstack|
    devstack.vm.box      = conf['vagrant_box']
    devstack.vm.box_url  = conf['vagrant_box_url']
    devstack.vm.hostname = conf['hostname']
    devstack.vm.network :private_network, ip: conf['ip_address']
    devstack.vm.network :forwarded_port, guest: 80, host: 80
    devstack.vm.provider "virtualbox" do |v|
      v.customize ["modifyvm", :id, "--memory", conf['memory']]
    end
    devstack.vm.provision "shell" do |s|
      s.path = "post-install.sh"
      s.args = ["ceilometer"]
    end
  end
end
