#!/bin/bash

apt-get install -qqy git
git config --global url.https://.insteadof git:// 

git clone https://github.com/openstack-dev/devstack.git
./devstack/tools/create-stack-user.sh

cat <<EOL > devstack/local.conf
[[local|localrc]]
ADMIN_PASSWORD=password
DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=a682f596-76f3-11e3-b3b2-e716f9080d50
EOL

for arg in $@ 
do
   case $arg in
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
        esac
done

chown -R stack:stack devstack/
cd devstack
su stack -c "./stack.sh"
