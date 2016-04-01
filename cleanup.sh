#!/bin/bash

rm -rf stack/*
mkdir -p stack
sudo -E vagrant destroy -f
sudo rm /etc/exports
