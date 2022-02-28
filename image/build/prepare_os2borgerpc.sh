#!/bin/bash

# You have entered the squashed system as root.
export DEBIAN_FRONTEND=noninteractive

apt-get -y update
apt-get -y upgrade
# Ignore error about zsys daemon
apt-get -y install git

# Get code for OS2borgerPC

git clone https://github.com/magenta-mfm/image/
cd image
# TODO: Delete after merge to master
git checkout feature/48910_activate_superuser_desktop_shortcuts

# Run customization.

printf "\n\n%s\n\n" "=== RUNNING: image/scripts/os2borgerpc_setup.sh ==="
image/scripts/os2borgerpc_setup.sh
printf "\n\n%s\n\n" "=== RUNNING: image/scripts/finalize.sh ==="
image/scripts/finalize.sh

# Cleanup

apt-get -y autoremove
apt-get -y clean
cd ..
rm -rf image/
rm /tmp/*
