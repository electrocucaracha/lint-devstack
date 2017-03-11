#!/bin/bash

vagrant destroy -f
vagrant up

if [ -n "$1" ]; then
    git config --global --add gitreview.username $1;
fi

# Hook for helping to run tox tests and scripts before the local commit is made.
wget -O ./stack/pre-commit https://raw.githubusercontent.com/csmart/openstack-git-hooks/master/pre-commit
chmod u+x ./stack/pre-commit

for folder in `ls -d ./stack/*/.git`; do
    repo=$(echo $folder | awk -F . '{ print $2 }')
    echo "Setting up ${repo:7}"
    pushd ./$repo
    ln -s ../pre-commit  ./.git/hooks/pre-commit
    git review -s &
    python ./tools/install_venv.py &
    popd
done
