#!/bin/bash

./cleanup.sh
vagrant up

if [ -z "$1" ]; then
  git config --global --add gitreview.username $1;
fi

# Hook for helping to run tox tests and scripts before the local commit is made.
wget -O ./stack/pre-commit https://raw.githubusercontent.com/csmart/openstack-git-hooks/master/pre-commit
chmod u+x ./stack/pre-commit

for folder in `ls -d ./stack/{cinder,glance,horizon,neutron,nova}`
do
  pushd $folder
  ln -s ../pre-commit  ./.git/hooks/pre-commit
  git review -s &
  pyvenv .venv
  python ./tools/install_venv.py &
  popd
done
