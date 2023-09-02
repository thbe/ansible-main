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
# Purpose:      Clone inventory based on name and link it into ansible-main
#

if [ -z ${1} ]; then
  echo "No inventory name set, exiting!"
  exit
else
  INVENTORY=${1}
fi

cd ..
gh repo clone thbe/ansible-inventory-${INVENTORY}
cd ansible-main/inventory
ln -s ../../ansible-inventory-${INVENTORY} ${INVENTORY}
cd ..
