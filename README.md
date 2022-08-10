# Lint Devstack
<!-- markdown-link-check-disable-next-line -->
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Super-Linter](https://github.com/electrocucaracha/lint-devstack/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)
![visitors](https://visitor-badge.glitch.me/badge?page_id=electrocucaracha.lint-devstack)

This project offers an automated process to provision a [Devstack][1]
development environment for working with OpenStack projects. The
Virtual Machine is configured to share the OpenStack's projects source
code to host machine. As result, it's possible to run system tests
and use a local IDE during development.

## Setup

This project uses [Vagrant tool][2] for provisioning Virtual Machines
automatically. It's highly recommended to use the  *setup.sh* script
of the [bootstrap-vagrant project][3] for installing Vagrant
dependencies and plugins required for its project. The script
supports two Virtualization providers (Libvirt and VirtualBox).

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to deploy the demo with the
following instruction:

    vagrant up

## Quick setup

It's possible to run this project without having to clone it. The following
instruction allows its remote execution:

    curl -fsSL https://raw.githubusercontent.com/electrocucaracha/lint-devstack/master/setup.sh | OS_PROJECT_LIST=octavia bash

### Environment variables

| Name              | Default     | Description                                 |
|:------------------|:------------|:--------------------------------------------|
| OS_PROJECT_LIST   |             | List of OpenStack projects to be enabled    |
| DEVSTACK_RELEASE  | stable/yoga | Devstack Release                            |
| PASSWORD          |             | Password used for all the Devstack services |

[1]: http://docs.openstack.org/developer/devstack/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
