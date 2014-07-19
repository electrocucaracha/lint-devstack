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
    devstack.vm.provision :shell, :inline => <<-SCRIPT
      apt-get install -qqy git
      git clone https://github.com/openstack-dev/devstack.git
      ./devstack/tools/create-stack-user.sh
      touch devstack/local.conf
      echo [[local|localrc]] >> devstack/local.conf
      echo ADMIN_PASSWORD='password' >> devstack/local.conf
      echo DATABASE_PASSWORD='password' >> devstack/local.conf
      echo RABBIT_PASSWORD='password' >> devstack/local.conf
      echo SERVICE_PASSWORD='password' >> devstack/local.conf
      echo SERVICE_TOKEN=a682f596-76f3-11e3-b3b2-e716f9080d50 >> devstack/local.conf
      chown -R stack devstack/
      cd devstack
      git config --global url.https://.insteadof git:// 
      su stack -c "./stack.sh"
   SCRIPT
  end
end
