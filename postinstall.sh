#!/bin/bash

PASSWORD='password'

# Setup proxy variables
if [ -f /home/vagrant/shared/sources.list ]
then
  cp /home/vagrant/shared/sources.list /etc/apt/sources.list
fi

apt-get update -y
apt-get install -y sudo git

cat <<EOL > /home/vagrant/.gitconfig
[url "https://"]
        insteadof = git://
EOL

git clone https://github.com/openstack-dev/devstack.git

token=`openssl rand -hex 10`
cat <<EOL > devstack/local.conf
[[local|localrc]]
ADMIN_PASSWORD=${PASSWORD}
DATABASE_PASSWORD=${PASSWORD}
RABBIT_PASSWORD=${PASSWORD}
SERVICE_PASSWORD=${PASSWORD}
SERVICE_TOKEN=${token}
ENABLE_DEBUG_LOG_LEVEL=False
DATA_DIR=/home/vagrant/data
EOL

for arg in $@ 
do
   case $arg in
        "tempest" )
          echo "ENABLED_SERVICES+=,tempest">> devstack/local.conf ;;
        "neutron" )
          echo "ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta">> devstack/local.conf
          echo "Q_USE_SECGROUP=True">> devstack/local.conf
          echo "disable_service n-net">> devstack/local.conf ;; # Do not use Nova-Network
        "neutron-metering" )
          echo "ENABLED_SERVICES+=,q-metering">> devstack/local.conf ;;
        "neutron-vpnaas" )
          echo "ENABLED_SERVICES+=,q-vpnaas">> devstack/local.conf
          echo "enable_plugin neutron-vpnaas https://git.openstack.org/openstack/neutron-vpnaas">> devstack/local.conf ;;
        "neutron-fwaas" )
          echo "ENABLED_SERVICES+=,q-fwaas">> devstack/local.conf
          echo "enable_plugin neutron-fwaas https://git.openstack.org/openstack/neutron-fwaas">> devstack/local.conf ;;
        "neutron-lbaas" )
          echo "ENABLED_SERVICES+=,q-lbaasv2">> devstack/local.conf
          echo "enable_plugin neutron-lbaas-dashboard https://git.openstack.org/openstack/neutron-lbaas-dashboard">> devstack/local.conf
          echo "enable_plugin neutron-lbaas https://git.openstack.org/openstack/neutron-lbaas">> devstack/local.conf ;;
        "octavia" )
          echo "ENABLED_SERVICES+=,octavia,o-cw,o-hk,o-hm,o-api">> devstack/local.conf
          echo "enable_plugin octavia https://git.openstack.org/openstack/octavia">> devstack/local.conf ;;
        "swift" )
          echo "SWIFT_HASH=swift">> devstack/local.conf
          echo "ENABLED_SERVICES+=,s-proxy,s-object,s-container,s-account">> devstack/local.conf ;;
        "horizon" )
          echo "ENABLED_SERVICES+=horizon">> devstack/local.conf ;;
        "heat" )
          echo "ENABLED_SERVICES+=heat,h-api,h-api-cfn,h-api-cw,h-eng">> devstack/local.conf ;;   
        "marconi" )
          echo "ENABLED_SERVICES+=,marconi-server">> devstack/local.conf ;;
        "ceilometer" )
          echo "enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer.git" >> devstack/local.conf ;;
        "rally" )
          git clone https://github.com/stackforge/rally
	  cp rally/contrib/devstack/lib/rally devstack/lib/
          cp rally/contrib/devstack/extras.d/70-rally.sh devstack/extras.d/
          echo "ENABLED_SERVICES+=,rally" >> devstack/local.conf ;;
	"barbican" )
	  apt-get install -qqy libssl-dev
	  git clone https://github.com/openstack/barbican.git
	  cp barbican/contrib/devstack/lib/barbican devstack/lib/
	  cp barbican/contrib/devstack/extras.d/70-barbican.sh devstack/extras.d/
	  echo "ENABLED_SERVICES+=,barbican" >> devstack/local.conf ;;
	"trove" )
          echo "ENABLED_SERVICES+=,trove,tr-api,tr-tmgr,tr-cond" >> devstack/local.conf ;;
	"sahara" ) # Sahara requires swift
          echo "enable_plugin sahara-dashboard git://git.openstack.org/openstack/sahara-dashboard">> devstack/local.conf
          echo "enable_plugin sahara git://git.openstack.org/openstack/sahara">> devstack/local.conf ;;
	"cloudkitty" ) # CloudKitty requires ceilometer and horizon
          echo "enable_plugin cloudkitty https://github.com/openstack/cloudkitty master">> devstack/local.conf
          echo "enable_service ck-api ck-proc">> devstack/local.conf ;;
	"docker" )
	  echo "VIRT_DRIVER=docker" >> devstack/local.conf ;;
        "osprofiler" )
          echo "CEILOMETER_NOTIFICATION_TOPICS=notifications,profiler" >> devstack/local.conf ;;
        "python-neutronclient" )
          echo "LIBS_FROM_GIT+=python-neutronclient" >> devstack/local.conf ;;
        "python-openstackclient" )
          echo "LIBS_FROM_GIT+=python-openstackclient" >> devstack/local.conf ;;
   esac
done

chown -R vagrant:vagrant devstack/
cd devstack
su vagrant -c "./stack.sh"

echo OFFLINE=True >> local.conf

# script /dev/null
