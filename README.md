Minimal Devstack
================

[![Build Status](https://api.travis-ci.org/electrocucaracha/vagrant-minimal-devstack.svg?branch=master)](https://api.travis-ci.org/electrocucaracha/vagrant-minimal-devstack)

This vagrant project pretends to collect information about setting up
development environments. It also is configured to share the source code
to host machine. As result, it's possible to run and test things isolated
and use and IDE for walking through the source during development.

> Visit [Devstack official site][1] for more information.

**Requirements:**

  * [Vagrant][2]
  * [VirtualBox][3] or [Libvirt][4]

**Steps for initialization:**

    $ git clone https://github.com/electrocucaracha/vagrant-minimal-devstack.git
    $ cd vagrant-minimal-devstack
    $ ./init.sh

OpenStack source code repositories are shared between host and guest computers.
This feature allows to use the advantages of a local IDE and verify those
changes in an isolated virtual environment.

**Steps to recreate:**

    $ ./recreate.sh

*Firewalld*

Given that synchonization uses NFS is possible to have some issues with
firewall. As a solution, it's necessary to add some rules to be setup in
firewalld servicei:

    # firewall-cmd --permanent --add-service rpc-bind
    # firewall-cmd --permanent --add-service nfs

This can be verified by running `# firewall-cmd --list-all`

[1]: http://docs.openstack.org/developer/devstack/
[2]: https://www.vagrantup.com/downloads.html
[3]: https://www.virtualbox.org/wiki/Downloads
[4]: http://libvirt.org/downloads.html
