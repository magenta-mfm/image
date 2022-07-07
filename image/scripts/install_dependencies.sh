#!/usr/bin/env bash

set -x

printf "\n\n%s\n\n" "Updating and upgrading packages, installing dependencies"

# Find current directory

DIR=$(dirname ${BASH_SOURCE[0]})

apt-get update &> /dev/null
RETVAL=$?
if [ $RETVAL -ne 0 ]; then
    echo "" 1>&2
    echo "ERROR: Apt repositories are not valid or cannot be reached from your network." 1>&2
    echo "Please fix and retry" 1>&2
    echo "" 1>&2
    exit 1
else
    echo "Repositories OK: Installing packages"
fi

# The DEPENDENCIES file contains packages/programs
# required by OS2borgerPC.
DEPENDENCIES=( $(cat "$DIR/DEPENDENCIES") )

dpkg -l | grep "^ii" > /tmp/scripts_installed_packages_list.txt

for  package in "${DEPENDENCIES[@]}"
do
    grep -w "ii  $package " /tmp/scripts_installed_packages_list.txt > /dev/null
    if [[ $? -ne 0 ]]; then
        PKGS_TO_INSTALL=$PKGS_TO_INSTALL" "$package
    fi
done

# upgrade
apt-get -y upgrade | tee /tmp/os2borgerpc_upgrade_log.txt
apt-get -y dist-upgrade | tee /tmp/os2borgerpc_upgrade_log.txt


if [ "$PKGS_TO_INSTALL" != "" ]; then
    echo  -n "Some dependencies are missing."
    echo " The following packages will be installed: $PKGS_TO_INSTALL"

    # Step 1: Check for valid APT repositories.

    # Step 2: Do the actual installation. Abort if it fails.
    # and install
    apt-get -y install $PKGS_TO_INSTALL | tee /tmp/os2borgerpc_install_log.txt
    RETVAL=$?
    if [ $RETVAL -ne 0 ]; then
        echo "" 1>&2
        echo "ERROR: Installation of dependencies failed." 1>&2
        echo "Please note that \"universe\" repository MUST be enabled" 1>&2
        echo "" 1>&2
        exit 1
    fi
else
    echo "No dependencies missing...?"
fi

echo "Install any missing language support packages"
apt-get install check-language-support
# Mark language support packages as explicitly installed as otherwise it seems later stages gets rid of some of them
# shellcheck disable=SC2046 # We want word-splitting here
apt-mark manual $(check-language-support --show-installed)

# Clean .deb cache to save space
apt-get -y autoremove --purge
apt-get -y clean

pip3 install os2borgerpc-client

# Setup unattended upgrades
"$DIR/apt_periodic_control.sh" security

# Randomize checkins with server.
"$DIR/randomize_jobmanager.sh" 5
