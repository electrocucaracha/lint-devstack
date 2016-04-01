#!/bin/bash

# Setup proxy variables

if [ -f /home/vagrant/shared/sources.list ]
then
  cp /home/vagrant/shared/sources.list /etc/apt/sources.list
fi

if [ -f /home/vagrant/shared/proxy.sh ]
then
  source /home/vagrant/shared/proxy.sh

  echo "export http_proxy=${http_proxy}" >> /etc/bash.bashrc
  echo "export https_proxy=${https_proxy}" >> /etc/bash.bashrc
  echo "export no_proxy=${no_proxy}" >> /etc/bash.bashrc
fi

apt-get update -y
apt-get install -y sudo git

cat <<EOL > /etc/gitconfig
[url "https://"]
        insteadof = git://
EOL


git clone https://github.com/openstack-dev/devstack.git
./devstack/tools/create-stack-user.sh

token=`openssl rand -hex 10`
cat <<EOL > devstack/local.conf
[[local|localrc]]
ADMIN_PASSWORD=password
DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=${token}
ENABLE_DEBUG_LOG_LEVEL=False
DATA_DIR=/home/vagrant/data
EOL

for arg in $@ 
do
   case $arg in
        "neutron" )
          echo "ENABLED_SERVICES+=,q-svc,q-agt,q-dhcp,q-l3,q-meta">> devstack/local.conf
          echo "disable_service n-net">> devstack/local.conf
          echo "disable_service tempest">> devstack/local.conf;;
        "swift" )
          echo "ENABLED_SERVICES+=,s-proxy,s-object,s-container,s-account">> devstack/local.conf ;;
        "heat" )
          echo "ENABLED_SERVICES+=heat,h-api,h-api-cfn,h-api-cw,h-eng">> devstack/local.conf ;;   
        "marconi" )
          echo "ENABLED_SERVICES+=,marconi-server">> devstack/local.conf ;;
        "ceilometer" )
          echo "ENABLED_SERVICES+=,ceilometer-acompute,ceilometer-acentral,ceilometer-anotification,ceilometer-collector,ceilometer-api,ceilometer-alarm-notifier,ceilometer-alarm-evaluator" >> devstack/local.conf ;;
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
	"sahara" )
	  echo "ENABLED_SERVICES+=,sahara" >> devstack/local.conf ;;
	"docker" )
	  echo "VIRT_DRIVER=docker" >> devstack/local.conf ;;
        "osprofiler" )
          echo "CEILOMETER_NOTIFICATION_TOPICS=notifications,profiler" >> devstack/local.conf ;;
   esac
done

## OSIC - Customization


## Devstack execution

chown -R stack:stack devstack/
cd devstack
su stack -c "./stack.sh"

# script /dev/null
