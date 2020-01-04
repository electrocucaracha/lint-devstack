# Lint Devstack
[![Build Status](https://api.travis-ci.org/electrocucaracha/lint-devstack.svg?branch=master)](https://api.travis-ci.org/electrocucaracha/lint-devstack)

This project offers an automated process to provision a Devstack[1] 
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

    $ curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to deploy the demo with the
following instruction:

    $ vagrant up

## License

Apache-2.0

[1]: http://docs.openstack.org/developer/devstack/
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
