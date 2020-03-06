#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o nounset
set -o pipefail

PASSWORD='password'

# shellcheck disable=SC1091
source /etc/os-release || source /usr/lib/os-release
case ${ID,,} in
    ubuntu|debian)
        sudo apt-get update
        sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl
    ;;
esac

pkgs=""
for pkg in sudo git; do
if ! command -v "$pkg"; then
    pkgs+=" $pkg"
fi
done
if [ -n "$pkgs" ]; then
    curl -fsSL http://bit.ly/install_pkg | PKG=$pkgs bash
fi

if [ ! -d /opt/stack/devstack ]; then
    sudo -E git clone --depth 1 https://github.com/openstack/devstack /opt/stack/devstack
    if [[ "$USER" != "vagrant" ]]; then
        sudo chown -R "$USER" /opt/stack/
    fi
fi

if [ ! -f local.conf ]; then
    pushd /opt/stack/devstack/
    cat <<EOL > local.conf
[[local|localrc]]
HOST_IP=${HOST_IP:-10.0.1.3}
DATA_DIR=$HOME/data
SERVICE_DIR=$HOME/status

LOGFILE=\$DATA_DIR/logs/stack.log
VERBOSE=True

MYSQL_PASSWORD=${PASSWORD}
DATABASE_PASSWORD=${PASSWORD}
SERVICE_TOKEN=$(openssl rand -hex 10)
SERVICE_PASSWORD=${PASSWORD}
ADMIN_PASSWORD=${PASSWORD}
RABBIT_PASSWORD=${PASSWORD}

REQUIREMENTS_DIR=$HOME/requirements
disable_service tempest
EOL

    # http://docs.openstack.org/developer/devstack/plugin-registry.html
    for arg in "$@"; do
        case $arg in
            "neutron-metering" )
                echo "ENABLED_SERVICES+=,q-metering">> local.conf ;;
            "neutron-vpnaas" )
                echo "ENABLED_SERVICES+=,q-vpnaas">> local.conf
                echo "enable_plugin neutron-vpnaas https://git.openstack.org/openstack/neutron-vpnaas">> local.conf ;;
            "neutron-fwaas" )
                echo "ENABLED_SERVICES+=,q-fwaas">> local.conf
                echo "enable_plugin neutron-fwaas https://git.openstack.org/openstack/neutron-fwaas">> local.conf ;;
            "neutron-lbaas" )
                echo "ENABLED_SERVICES+=,q-lbaasv2">> local.conf
                echo "enable_plugin neutron-lbaas-dashboard https://git.openstack.org/openstack/neutron-lbaas-dashboard">> local.conf
                echo "enable_plugin neutron-lbaas https://git.openstack.org/openstack/neutron-lbaas">> local.conf ;;
            "magnum" ) # magnum requires heat
                echo "enable_plugin magnum-ui https://git.openstack.org/openstack/magnum-ui">> local.conf
                echo "enable_plugin magnum https://git.openstack.org/openstack/magnum">> local.conf ;;
            "designate" )
                echo "ENABLED_SERVICES+=,designate,designate-central,designate-api,designate-pool-manager,designate-zone-manager,designate-mdns">> local.conf
                echo "enable_plugin designate https://git.openstack.org/openstack/designate">> local.conf ;;
            "octavia" )
                echo "ENABLED_SERVICES+=,octavia,o-cw,o-hk,o-hm,o-api">> local.conf
                echo "enable_plugin octavia https://git.openstack.org/openstack/octavia">> local.conf ;;
            "swift" )
                echo "SWIFT_HASH=swift">> local.conf
                echo "ENABLED_SERVICES+=,s-proxy,s-object,s-container,s-account">> local.conf ;;
            "horizon" )
                echo "ENABLED_SERVICES+=horizon">> local.conf ;;
            "heat" )
                echo "enable_plugin heat https://git.openstack.org/openstack/heat.git" >> local.conf ;;
            "marconi" )
                echo "ENABLED_SERVICES+=,marconi-server">> local.conf ;;
            "ceilometer" )
                echo "ENABLED_SERVICES+=,ceilometer-api">> local.conf
                echo "enable_plugin ceilometer https://git.openstack.org/openstack/ceilometer.git" >> local.conf ;;
            "rally" )
                git clone --depth 1 https://github.com/stackforge/rally /tmp/rally
                cp /tmp/rally/contrib/devstack/lib/rally lib/
                cp /tmp/rally/contrib/devstack/extras.d/70-rally.sh extras.d/
                echo "ENABLED_SERVICES+=,rally" >> local.conf ;;
            "barbican" )
                echo "enable_plugin barbican https://git.openstack.org/openstack/barbican.git" >> local.conf ;;
            "trove" )
                echo "ENABLED_SERVICES+=,trove,tr-api,tr-tmgr,tr-cond" >> local.conf ;;
            "sahara" ) # sahara requires swift
                echo "enable_plugin sahara-dashboard git://git.openstack.org/openstack/sahara-dashboard">> local.conf
                echo "enable_plugin sahara git://git.openstack.org/openstack/sahara">> local.conf ;;
            "cloudkitty" ) # cloudKitty requires ceilometer and horizon
                echo "enable_plugin cloudkitty https://github.com/openstack/cloudkitty master">> local.conf
                echo "enable_service ck-api ck-proc">> local.conf ;;
            "docker" )
                echo "VIRT_DRIVER=docker" >> local.conf ;;
            "osprofiler" )
                echo "CEILOMETER_NOTIFICATION_TOPICS=notifications,profiler" >> local.conf ;;
            "python-neutronclient" )
                echo "LIBS_FROM_GIT+=python-neutronclient" >> local.conf ;;
            "python-openstackclient" )
                echo "LIBS_FROM_GIT+=python-openstackclient" >> local.conf ;;
        esac
    done
    echo "# OFFLINE=True" >> local.conf
    popd
    cat ./post-configs/* >> /opt/stack/devstack/local.conf
fi
cd /opt/stack/devstack/
FORCE=yes ./stack.sh

echo "source /opt/stack/devstack/openrc admin admin" >> ~/.bashrc
# script /dev/null
