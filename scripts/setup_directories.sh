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
# Purpose:      Set up required directories
#

mkdir ../ansible-results
cd ../ansible-results
mkdir aide cis lynis permissions rkhunter
cd -
