#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018,2022
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o nounset
set -o pipefail
if [ "${DEBUG:-false}" == "true" ]; then
    set -o xtrace
    export PKG_DEBUG=true
fi

PASSWORD='password'
GIT_REPO_HOST="https://opendev.org/openstack"
LOCAL_CONFIG_PATH="/opt/stack/devstack/local.conf"

# https://docs.openstack.org/devstack/latest/plugin-registry.html
declare -A plugins=(
["barbican"]="barbican"
["ceilometer"]="ceilometer"
["cloudkitty"]="cloudkitty"
["designate"]="designate"
["heat"]="heat"
["magnum"]="magnum-ui,magnum"
["neutron-fwaas"]="neutron-fwaas"
["neutron-lbaas"]="neutron-lbaas,neutron-lbaas-dashboard"
["neutron-vpnaas"]="neutron-vpnaas"
["octavia"]="octavia"
["sahara"]="sahara-dashboard,sahara"
)

declare -A services=(
["ceilometer"]="ceilometer-api"
["cloudkitty"]="ck-api,ck-proc"
["designate"]="designate,designate-central,designate-api,designate-pool-manager,designate-zone-manager,designate-mdns"
["horizon"]="horizon"
["marconi"]="marconi-server"
["neutron-fwaas"]="q-fwaas"
["neutron-lbaas"]="q-lbaasv2"
["neutron-metering"]="q-metering"
["neutron-vpnaas"]="q-vpnaas"
["octavia"]="octavia,o-cw,o-hk,o-hm,o-api"
["rally"]="rally"
["swift"]="s-proxy,s-object,s-container,s-account"
["trove"]="trove,tr-api,tr-tmgr,tr-cond"
)

function _enable_kernel_attr {
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

function _enable_plugins {
    local os_project=$1

    if [[ ${plugins[$os_project]:+1} ]]; then
        devstack_plugins=${plugins[$os_project]}
        for plugin in ${devstack_plugins//,/ }; do
            _enable_plugin "$plugin"
        done
    fi
}

function _enable_plugin {
    _append_config_line "enable_plugin $1 $GIT_REPO_HOST/$1.git"
}

function _enable_services {
    local os_project=$1

    if [[ ${services[$os_project]:+1} ]]; then
        _enable_service "${services[$os_project]//,/ }"
    fi
}

function _enable_service {
    _append_config_line "enable_service $1"
}

function _append_config_line {
    echo "$1" | tee --append  "$LOCAL_CONFIG_PATH"
}

function _disable_ipv6 {
    _enable_kernel_attr net.ipv6.conf.all.disable_ipv6
    _enable_kernel_attr net.ipv6.conf.default.disable_ipv6
    sudo sysctl -p
}

function _manage_deps {
    # shellcheck disable=SC1091
    source /etc/os-release || source /usr/lib/os-release
    case ${ID,,} in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl
            sudo apt-get remove -y python3-yaml python3-httplib2 python3-pyasn1 postgresql postgresql-client
        ;;
    esac

    # NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
    curl -fsSL http://bit.ly/install_pkg | PKG_COMMANDS_LIST="sudo,git" bash
}

function _clone_repo {
    if [ ! -d /opt/stack/devstack ]; then
        sudo -E git clone --depth 1 -b "${DEVSTACK_RELEASE:-stable/yoga}" "$GIT_REPO_HOST/devstack" /opt/stack/devstack
        sudo chown -R "$USER" /opt/stack/
    fi
}

function _create_local_conf {
    mkdir -p /opt/stack/devstack/

    if [ ! -f "$LOCAL_CONFIG_PATH" ]; then
        pushd /opt/stack/devstack/
        cat <<EOL > "$LOCAL_CONFIG_PATH"
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
            _append_config_line "FLOATING_RANGE=$FLOATING_RANGE"
        fi
        if [[ -n "${PUBLIC_NETWORK_GATEWAY:-}" ]]; then
            _append_config_line "PUBLIC_NETWORK_GATEWAY=$PUBLIC_NETWORK_GATEWAY"
            _append_config_line "PUBLIC_INTERFACE=eth1"
        fi
        if [[ -n "${FIXED_RANGE:-}" ]]; then
            _append_config_line "FIXED_RANGE=$FIXED_RANGE"
        fi

        for arg in "$@"; do
            _enable_plugins "$arg"
            _enable_services "$arg"
            case $arg in
                "osprofiler" )
                    _append_config_line "CEILOMETER_NOTIFICATION_TOPICS=notifications,profiler";;
                "python-neutronclient" )
                    _append_config_line "LIBS_FROM_GIT+=python-neutronclient";;
                "python-openstackclient" )
                    _append_config_line "LIBS_FROM_GIT+=python-openstackclient";;
                "rally" )
                    git clone --depth 1 https://opendev.org/stackforge/rally /tmp/rally
                    cp /tmp/rally/contrib/devstack/lib/rally lib/
                    cp /tmp/rally/contrib/devstack/extras.d/70-rally.sh extras.d/ ;;
                "swift" )
                    _append_config_line "SWIFT_HASH=swift";;
            esac
        done
        _append_config_line "# OFFLINE=True"
        popd
        cat ./post-configs/* >> "$LOCAL_CONFIG_PATH"
    fi
}

function main {
    _disable_ipv6
    _manage_deps
    _clone_repo
    _create_local_conf "$@"

    cd /opt/stack/devstack/
    FORCE=yes ./stack.sh

    echo "source /opt/stack/devstack/openrc admin admin" >> ~/.bashrc
    # script /dev/null
}

if [[ "${__name__:-"__main__"}" == "__main__" ]]; then
    main "$@"
fi
