#! /usr/bin/env bash
#
# Author:       Thomas Bendler <code@thbe.org>
# Date:         Tue Feb 14 12:45:53 CET 2023
#
# Note:         To debug the script change the shebang to: /usr/bin/env bash -vx
#
# Prerequisite: This release needs a shell that could handle functions.
#               If shell is not able to handle functions, remove the
#               error section.
#
# Release:      0.9.0
#
# ChangeLog:    v0.9.0 - Initial release
#
# Purpose:      Upgrade installed roles, collections and submodules
#

git submodule update --remote

ansible-galaxy install thbe.common -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.platform -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.rhel -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.security -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.baseline -p roles/ --force-with-deps --verbose
ansible-galaxy install thbe.sap -p roles/ --force-with-deps --verbose

ansible-galaxy collection install ansible.posix --upgrade --force-with-deps --verbose
ansible-galaxy collection install community.general --upgrade --force-with-deps --verbose
