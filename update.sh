#!/bin/bash

for folder in `ls -d ./stack/{cinder,glance,horizon,neutron,nova}`
do
  pushd $folder
  git checkout master && git pull origin master &
  popd
done
