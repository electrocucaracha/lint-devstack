#!/bin/bash

./cleanup.sh
sudo -E vagrant up

if [ -z "$1" ]; then
  git config --global --add gitreview.username $1;
fi

for folder in `ls -d ./stack/{cinder,glance,horizon,neutron,nova}`
do
  pushd $folder
  git review -s &
  python ./tools/install_venv.py &
  popd
done
