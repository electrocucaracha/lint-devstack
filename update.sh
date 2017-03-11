#!/bin/bash

for folder in `ls -d ./stack/*/.git`; do
    repo=$(echo $folder | awk -F . '{ print $2 }')
    echo "Updating ${repo:7}"
    pushd ./$repo
    git checkout master && git pull origin master &
    popd
done
