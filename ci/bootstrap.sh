#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2022
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o nounset
set -o pipefail

# info() - This function prints an information message in the standard output
function info {
    _print_msg "INFO" "$1"
    echo "::notice::$1"
}

function _print_msg {
    echo "$(date +%H:%M:%S) - $1: $2"
}

function destroy_vm {
    info "Destroying Devstack instance..."
    # NOTE: Shutdown instances avoids VBOX_E_INVALID_OBJECT_STATE issues
    $VAGRANT_CMD halt
    $VAGRANT_CMD destroy -f
}

if ! command -v vagrant > /dev/null; then
    # NOTE: Shorten link -> https://github.com/electrocucaracha/bootstrap-vagrant
    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash
fi

VAGRANT_CMD=""
if [[ "${SUDO_VAGRANT_CMD:-false}" == "true" ]]; then
    VAGRANT_CMD="sudo -H"
fi
VAGRANT_CMD+=" $(command -v vagrant)"
# shellcheck disable=SC2034
VAGRANT_CMD_UP="$VAGRANT_CMD up --no-destroy-on-error"

info "Define target node"
    cat <<EOL > ../override_config.yml
name: devstack
os:
  name: ${OS:-ubuntu}
  release: ${RELEASE:-focal}
memory: ${MEMORY:-6144}
cpus: 2
numa_nodes: # Total memory for NUMA nodes must be equal to RAM size
  - cpus: 0-1
    memory: ${MEMORY:-6144}
pmem:
  size: ${MEMORY:-6144}M # This value may affect the currentMemory libvirt tag
  slots: 2
  max_size: 128G
  vNVDIMMs:
    - mem_id: mem0
      id: nv0
      share: "on"
      path: /dev/shm
      size: 2G
EOL
destroy_vm

info "Provision target node"
$VAGRANT_CMD_UP
