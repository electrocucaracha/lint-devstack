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
plugins=(
	"aodh"
	"barbican"
	"blazar"
	"ceilometer"
	"ceilometer-powervm"
	"cinderlib"
	"cloudkitty"
	"cyborg"
	"designate"
	"devstack-plugin-amqp1"
	"devstack-plugin-ceph"
	"devstack-plugin-container"
	"devstack-plugin-kafka"
	"devstack-plugin-nfs"
	"devstack-plugin-open-cas"
	"ec2-api"
	"freezer"
	"freezer-api"
	"freezer-tempest-plugin"
	"freezer-web-ui"
	"heat"
	"heat-dashboard"
	"ironic"
	"ironic-inspector"
	"ironic-prometheus-exporter"
	"ironic-ui"
	"keystone"
	"kuryr-kubernetes"
	"kuryr-libnetwork"
	"kuryr-tempest-plugin"
	"magnum"
	"magnum-ui"
	"manila"
	"manila-tempest-plugin"
	"manila-ui"
	"masakari"
	"mistral"
	"monasca-api"
	"monasca-events-api"
	"monasca-tempest-plugin"
	"murano"
	"networking-bagpipe"
	"networking-baremetal"
	"networking-bgpvpn"
	"networking-generic-switch"
	"networking-hyperv"
	"networking-odl"
	"networking-powervm"
	"networking-sfc"
	"neutron"
	"neutron-dynamic-routing"
	"neutron-fwaas"
	"neutron-fwaas-dashboard"
	"neutron-tempest-plugin"
	"neutron-vpnaas"
	"neutron-vpnaas-dashboard"
	"nova-powervm"
	"octavia"
	"octavia-dashboard"
	"octavia-tempest-plugin"
	"openstacksdk"
	"osprofiler"
	"oswin-tempest-plugin"
	"ovn-octavia-provider"
	"patrole"
	"rally-openstack"
	"sahara"
	"sahara-dashboard"
	"senlin"
	"shade"
	"skyline-apiserver"
	"solum"
	"storlets"
	"tacker"
	"tap-as-a-service"
	"telemetry-tempest-plugin"
	"trove"
	"trove-dashboard"
	"venus"
	"venus-dashboard"
	"vitrage"
	"vitrage-dashboard"
	"vitrage-tempest-plugin"
	"watcher"
	"watcher-dashboard"
	"whitebox-tempest-plugin"
	"zaqar"
	"zaqar-ui"
	"zun"
	"zun-ui"
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

		sudo sysctl "$attr=1"
	fi
}

function _enable_plugin {
	if [[ ${plugins[*]} =~ (^|[[:space:]])"$1"($|[[:space:]]) ]]; then
		_append_config_line "enable_plugin $1 $GIT_REPO_HOST/$1.git"
	fi
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

function _disable_service {
	_append_config_line "disable_service $1"
}

function _append_config_line {
	if ! grep -q "$1" "$LOCAL_CONFIG_PATH"; then
		echo "$1" | tee --append "$LOCAL_CONFIG_PATH"
	fi
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
	ubuntu | debian)
		sudo apt-get update
		sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl
		sudo apt-get remove -y python3-yaml python3-httplib2 python3-pyasn1 postgresql postgresql-client python3-cryptography
		;;
	esac

	# NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
	curl -fsSL http://bit.ly/install_pkg | PKG_COMMANDS_LIST="sudo,git" bash
}

function _clone_repo {
	if [ ! -d /opt/stack/devstack ]; then
		sudo -E git clone --depth 1 -b "${DEVSTACK_RELEASE:-stable/2024.2}" "$GIT_REPO_HOST/devstack" /opt/stack/devstack
		sudo chown -R "$USER" /opt/stack/
	fi
}

function _set_env_values {
	for env_var in $(printenv | grep "LINT_DEVSTACK_"); do
		_append_config_line "${env_var//LINT_DEVSTACK_/}"
	done
}

function _create_local_conf {
	mkdir -p /opt/stack/devstack/

	if [ ! -f "$LOCAL_CONFIG_PATH" ]; then
		pushd /opt/stack/devstack/
		cat <<EOL >"$LOCAL_CONFIG_PATH"
[[local|localrc]]
HOST_IP=$(ip route get 8.8.8.8 | grep "^8." | awk '{ print $7 }')
SERVICE_DIR=$HOME/status
GLOBAL_VENV=False
LOGFILE=\$DATA_DIR/logs/stack.log
VERBOSE=True
IP_VERSION=4
IPV6_ENABLED=False

MYSQL_PASSWORD=${MYSQL_PASSWORD:-$PASSWORD}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-$PASSWORD}
SERVICE_TOKEN=$(openssl rand -hex 10)
SERVICE_PASSWORD=${SERVICE_PASSWORD:-$PASSWORD}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-$PASSWORD}
RABBIT_PASSWORD=${RABBIT_PASSWORD:-$PASSWORD}

REQUIREMENTS_DIR=$HOME/requirements
EOL
		_set_env_values
		if [ -n "${OS_PROJECT_LIST+x}" ]; then
			for project in ${OS_PROJECT_LIST//,/ }; do
				_enable_plugin "$project"
				_enable_services "$project"
				case $project in
				"osprofiler")
					_append_config_line "CEILOMETER_NOTIFICATION_TOPICS=notifications,profiler"
					;;
				"magnum")
					# Enable barbican service and use it to store TLS certificates
					_enable_plugin "barbican"
					_enable_plugin "heat"
					;;
				"python-neutronclient")
					_append_config_line "LIBS_FROM_GIT+=python-neutronclient"
					;;
				"python-openstackclient")
					_append_config_line "LIBS_FROM_GIT+=python-openstackclient"
					;;
				"rally")
					git clone --depth 1 https://opendev.org/stackforge/rally /tmp/rally
					cp /tmp/rally/contrib/devstack/lib/rally lib/
					cp /tmp/rally/contrib/devstack/extras.d/70-rally.sh extras.d/
					;;
				"swift")
					_append_config_line "SWIFT_HASH=swift"
					;;
				esac
			done
		fi
		if [ -n "${OS_DISABLE_SVC_LIST+x}" ]; then
			for service in ${OS_DISABLE_SVC_LIST//,/ }; do
				_disable_service "$service"
			done
		fi
		_append_config_line "# OFFLINE=True"
		popd
		cat ./post-configs/* >>"$LOCAL_CONFIG_PATH"
	fi
}

function main {
	_disable_ipv6
	_manage_deps
	_clone_repo
	_create_local_conf

	cd /opt/stack/devstack/
	FORCE=yes ./stack.sh

	echo "source /opt/stack/devstack/openrc admin admin" >>~/.bashrc
	# script /dev/null
}

if [[ ${__name__:-"__main__"} == "__main__" ]]; then
	main
fi
