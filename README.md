# Vagrant [Devstack][1]
[![Build Status](https://api.travis-ci.org/electrocucaracha/vagrant-minimal-devstack.svg?branch=master)](https://api.travis-ci.org/electrocucaracha/vagrant-minimal-devstack)

This vagrant project pretends to collect information about setting up
development environments. It also is configured to share the source code
to host machine. As result, it's possible to run and test things isolated
and use and IDE for walking through the source during development.

## Execution

This project uses [Vagrant tool][2] for provisioning Virtual Machines
automatically. The [setup](setup.sh) bash script contains the
Linux instructions to install dependencies and plugins required for
its usage. This script supports two Virtualization technologies
([VirtualBox][3] and [Libvirt][4]).

    $ ./setup.sh -p libvirt

Once Vagrant is installed, it's possible to provision a cluster using
the following instructions:

    $ vagrant up

## Known issues

### Firewalld

OpenStack source code folders are shared with the host using NFS provided
by the host machine. This service requires a specific rule to be setup in
firewalld service.  In order to allow traffic between host and guest this
service must be configured properly:

    # firewall-cmd --permanent --add-service rpc-bind
    # firewall-cmd --permanent --add-service nfs

This can be verified by running `# firewall-cmd --list-all`

[1]: http://docs.openstack.org/developer/devstack/
[2]: https://www.vagrantup.com/downloads.html
[3]: https://www.virtualbox.org/wiki/Downloads
[4]: http://libvirt.org/downloads.html
