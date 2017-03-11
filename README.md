Minimal Devstack
================

This vagrant project pretends to collect information about setting up
development environments. It also is configured to share the source code
to host machine. As result, it's possible to run and test things isolated
and use and IDE for walking through the source during development.

For more information about Devstack, take a look of
[the official site] (http://docs.openstack.org/developer/devstack/).

## Requirements:

  * Vagrant
  * VirtualBox or Libvirt

## Steps for execution:

    $ git clone https://github.com/electrocucaracha/vagrant-minimal-devstack.git
    $ cd vagrant-minimal-devstack
    $ ./recreate.sh

**Firewalld**

OpenStack source code folders are shared with the host using NFS provided by the
host machine. This service requires a specific rule to be setup in firewalld
service.  In order to allow traffic between host and guest this service must be
configured properly:

    # firewall-cmd --permanent --add-service rpc-bind
    # firewall-cmd --permanent --add-service nfs

This can be verified by running `# firewall-cmd --list-all`
