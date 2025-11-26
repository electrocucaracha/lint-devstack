# Lint Devstack

<!-- markdown-link-check-disable-next-line -->

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Super-Linter](https://github.com/electrocucaracha/lint-devstack/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

<!-- markdown-link-check-disable-next-line -->

![visitors](https://visitor-badge.laobi.icu/badge?page_id=electrocucaracha.lint-devstack)
[![Scc Code Badge](https://sloc.xyz/github/electrocucaracha/lint-devstack?category=code)](https://github.com/boyter/scc/)
[![Scc COCOMO Badge](https://sloc.xyz/github/electrocucaracha/lint-devstack?category=cocomo)](https://github.com/boyter/scc/)

## Overview

This project offers an automated process to provision a
[Devstack][1] development environment for working with OpenStack
projects.
The Virtual Machine is configured to share the OpenStack's projects
source code to host machine.
As result, it's possible to run system tests and use a local IDE
during development.

### Key Features

- **Automated Provisioning**:
  Uses Vagrant and shell scripts to automate the complete DevStack
  setup
- **Multi-Project Support**:
  Enables flexible installation of 100+ OpenStack projects and
  plugins
- **Development-Ready**:
  Provides shared source code between host and VM for seamless IDE
  integration
- **Service Management**:
  Dynamically enables/disables services based on project requirements
- **Configuration Flexibility**:
  Supports custom environment variables for advanced configuration
- **Multi-Distribution Support**:
  Compatible with Ubuntu, Debian, and other Linux distributions

## Setup

This project uses [Vagrant tool][2] for provisioning Virtual Machines
automatically.
It's highly recommended to use the _setup.sh_ script of the
[bootstrap-vagrant project][3] for installing Vagrant dependencies
and plugins required for its project.
The script supports two Virtualization providers (Libvirt and
VirtualBox).

    curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to deploy the demo with the
following instruction:

    vagrant up

## Quick setup

It's possible to run this project without having to clone it.
The following instruction allows its remote execution:

    curl -fsSL https://raw.githubusercontent.com/electrocucaracha/lint-devstack/master/setup.sh | OS_PROJECT_LIST=octavia bash

### Environment variables

| Name                  | Default       | Description                                                          |
| :-------------------- | :------------ | :------------------------------------------------------------------- |
| `OS_PROJECT_LIST`     |               | Comma-separated list of OpenStack projects/plugins to enable         |
| `OS_DISABLE_SVC_LIST` |               | Comma-separated list of Devstack services to disable                 |
| `DEVSTACK_RELEASE`    | stable/2025.2 | Devstack release branch (e.g., stable/2024.2, master)                |
| `PASSWORD`            | password      | Default password for all Devstack services                           |
| `MYSQL_PASSWORD`      | password      | MySQL database password                                              |
| `DATABASE_PASSWORD`   | password      | Database connection password                                         |
| `SERVICE_PASSWORD`    | password      | OpenStack service password                                           |
| `ADMIN_PASSWORD`      | password      | OpenStack admin user password                                        |
| `RABBIT_PASSWORD`     | password      | RabbitMQ password                                                    |
| `DEBUG`               | false         | Enable debug output (set to "true" to enable verbose logging)        |
| `LINT_DEVSTACK_*`     |               | Custom Devstack configuration variables (prefix with LINT*DEVSTACK*) |

#### Notes on Environment Variables

- **OS_PROJECT_LIST**:
  Accepts project names from the
  [OpenStack Plugin Registry](https://docs.openstack.org/devstack/latest/plugin-registry.html).
  Multiple projects should be comma-separated
  (e.g., `OS_PROJECT_LIST=octavia,neutron,heat`)
- **Custom Configuration**:
  Any variable prefixed with `LINT_DEVSTACK_` will be automatically
  added to the Devstack local.conf file with the prefix removed
  (e.g., `LINT_DEVSTACK_OFFLINE=True` becomes `OFFLINE=True`)
- **Password Management**:
  Individual password variables override the generic `PASSWORD`
  variable for specific components

[1]: http://docs.openstack.org/developer/devstack/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
