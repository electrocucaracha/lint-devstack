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
GIT_REPO_HOST="https://opendev.org/openstack"

# enable_kernel_attr() - Set a kernel attribute to true
function enable_kernel_attr {
    local attr="$1"

    if [ "$(sysctl -n "$attr")" != "1" ]; then
        if [ -d /etc/sysctl.d ]; then
            echo "$attr=1" | sudo tee "/etc/sysctl.d/$attr.conf"
        elif [ -f /etc/sysctl.conf ]; then
            echo "$attr=1" | sudo tee --append /etc/sysctl.conf
        fi

        sysctl "$attr=1"
    fi
}

enable_kernel_attr net.ipv6.conf.all.disable_ipv6
enable_kernel_attr net.ipv6.conf.default.disable_ipv6
sudo sysctl -p

# shellcheck disable=SC1091
source /etc/os-release || source /usr/lib/os-release
case ${ID,,} in
    ubuntu|debian)
        sudo apt-get update
        sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl
        sudo apt-get remove -y python3-yaml python3-httplib2 python3-pyasn1 postgresql postgresql-client
    ;;
esac

curl -fsSL http://bit.ly/install_pkg | PKG_COMMANDS_LIST="sudo,git" bash

if [ ! -d /opt/stack/devstack ]; then
    sudo -E git clone --depth 1 -b "${DEVSTACK_RELEASE:-stable/yoga}" "$GIT_REPO_HOST/devstack" /opt/stack/devstack
    sudo chown -R "$USER" /opt/stack/
fi

if [ ! -f local.conf ]; then
    pushd /opt/stack/devstack/
    cat <<EOL > local.conf
[[local|localrc]]
DATA_DIR=$HOME/data
SERVICE_DIR=$HOME/status
LOGFILE=\$DATA_DIR/logs/stack.log
VERBOSE=True
IP_VERSION=4

MYSQL_PASSWORD=${PASSWORD}
DATABASE_PASSWORD=${PASSWORD}
SERVICE_TOKEN=$(openssl rand -hex 10)
SERVICE_PASSWORD=${PASSWORD}
ADMIN_PASSWORD=${PASSWORD}
RABBIT_PASSWORD=${PASSWORD}

REQUIREMENTS_DIR=$HOME/requirements
disable_service tempest
EOL
    if [[ -n "${FLOATING_RANGE:-}" ]]; then
        echo "FLOATING_RANGE=$FLOATING_RANGE" | tee --append local.conf
    fi
    if [[ -n "${PUBLIC_NETWORK_GATEWAY:-}" ]]; then
        echo "PUBLIC_NETWORK_GATEWAY=$PUBLIC_NETWORK_GATEWAY" | tee --append local.conf
        echo "PUBLIC_INTERFACE=eth1" | tee --append local.conf
    fi
    if [[ -n "${FIXED_RANGE:-}" ]]; then
        echo "FIXED_RANGE=$FIXED_RANGE" | tee --append local.conf
    fi

    # http://docs.openstack.org/developer/devstack/plugin-registry.html
    for arg in "$@"; do
        case $arg in
            "barbican" )
                echo "enable_plugin barbican $GIT_REPO_HOST/barbican.git" >> local.conf ;;
            "ceilometer" )
                echo "ENABLED_SERVICES+=,ceilometer-api">> local.conf
                echo "enable_plugin ceilometer $GIT_REPO_HOST/ceilometer.git" >> local.conf ;;
            "cloudkitty" ) # cloudKitty requires ceilometer and horizon
                echo "enable_plugin cloudkitty $GIT_REPO_HOST/cloudkitty master">> local.conf
                echo "enable_service ck-api ck-proc">> local.conf ;;
            "designate" )
                echo "ENABLED_SERVICES+=,designate,designate-central,designate-api,designate-pool-manager,designate-zone-manager,designate-mdns">> local.conf
                echo "enable_plugin designate $GIT_REPO_HOST/designate">> local.conf ;;
            "docker" )
                echo "VIRT_DRIVER=docker" >> local.conf ;;
            "heat" )
                echo "enable_plugin heat $GIT_REPO_HOST/heat.git" >> local.conf ;;
            "horizon" )
                echo "ENABLED_SERVICES+=horizon">> local.conf ;;
            "magnum" ) # magnum requires heat
                echo "enable_plugin magnum-ui $GIT_REPO_HOST/magnum-ui">> local.conf
                echo "enable_plugin magnum $GIT_REPO_HOST/magnum">> local.conf ;;
            "marconi" )
                echo "ENABLED_SERVICES+=,marconi-server">> local.conf ;;
            "neutron-fwaas" )
                echo "ENABLED_SERVICES+=,q-fwaas">> local.conf
                echo "enable_plugin neutron-fwaas $GIT_REPO_HOST/neutron-fwaas">> local.conf ;;
            "neutron-lbaas" )
                echo "ENABLED_SERVICES+=,q-lbaasv2">> local.conf
                echo "enable_plugin neutron-lbaas-dashboard $GIT_REPO_HOST/neutron-lbaas-dashboard">> local.conf
                echo "enable_plugin neutron-lbaas $GIT_REPO_HOST/neutron-lbaas">> local.conf ;;
            "neutron-metering" )
                echo "ENABLED_SERVICES+=,q-metering">> local.conf ;;
            "neutron-vpnaas" )
                echo "ENABLED_SERVICES+=,q-vpnaas">> local.conf
                echo "enable_plugin neutron-vpnaas $GIT_REPO_HOST/neutron-vpnaas">> local.conf ;;
            "octavia" )
                echo "ENABLED_SERVICES+=,octavia,o-cw,o-hk,o-hm,o-api">> local.conf
                echo "enable_plugin octavia $GIT_REPO_HOST/octavia">> local.conf ;;
            "osprofiler" )
                echo "CEILOMETER_NOTIFICATION_TOPICS=notifications,profiler" >> local.conf ;;
            "python-neutronclient" )
                echo "LIBS_FROM_GIT+=python-neutronclient" >> local.conf ;;
            "python-openstackclient" )
                echo "LIBS_FROM_GIT+=python-openstackclient" >> local.conf ;;
            "rally" )
                git clone --depth 1 https://opendev.org/stackforge/rally /tmp/rally
                cp /tmp/rally/contrib/devstack/lib/rally lib/
                cp /tmp/rally/contrib/devstack/extras.d/70-rally.sh extras.d/
                echo "ENABLED_SERVICES+=,rally" >> local.conf ;;
            "sahara" ) # sahara requires swift
                echo "enable_plugin sahara-dashboard $GIT_REPO_HOST/sahara-dashboard">> local.conf
                echo "enable_plugin sahara $GIT_REPO_HOST/sahara">> local.conf ;;
            "swift" )
                echo "SWIFT_HASH=swift">> local.conf
                echo "ENABLED_SERVICES+=,s-proxy,s-object,s-container,s-account">> local.conf ;;
            "trove" )
                echo "ENABLED_SERVICES+=,trove,tr-api,tr-tmgr,tr-cond" >> local.conf ;;
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
