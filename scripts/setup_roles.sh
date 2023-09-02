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
# Purpose:      Set up required roles and collections
#

git submodule update --init --recursive

ansible-galaxy install -r requirements.yml -p roles/ --verbose
ansible-galaxy collection install -r requirements.yml --verbose
