#!/bin/bash
#
# Author: Daniel Martín
# 
# This script contains common functions.
# 
# History: 15-Nov-2012 dmartin    Initial version
#
# This file is part of iOSCoffeeShop.
#
# iOSCoffeeShop is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iOSCoffeeShop is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iOSCoffeeShop.  If not, see <http://www.gnu.org/licenses/>.

function die() {
    # This gets invoked when your coffee is not going to be brewed...
    # :-(
    echo ""
    echo "FATAL: $*" >&2
    exit 1
}

function show_progress() {
    echo "$@"
}

function show_coffee_shop_usage() {
    echo "Usage: $0 [-v version] [-p provisioning_profile] [-c developer_certificate] [-s sdk] [-r] [-b] [-g] [-l] [-a] [-d product_name] [-o output_dir] REPO_URI REPO_NAME"
    echo "   -r                 Compile a release version of the app"
    echo "   -b                 The URL is an SVN repository"
    echo "   -g                 The URL is a Git repository"
    echo "   -l                 Perform a validation step to the .ipa"
    echo "   -a                 Archive the .ipa"
    echo "   REPO_URI           Repository URI"
    echo "   PROJECT_NAME       Project name (without .xcodeproj extension)"
    die "Invalid arguments"
}

function show_coffee_maker_usage() {
    echo "Usage: $0 PROJECT_NAME VERSION PRODUCT_NAME PROVISIONING_PROFILE CODE_SIGN_IDENTITY SDK CONFIGURARION DEST_DIR VALIDATE_IPA ARCHIVE_IPA"
    die "Invalid arguments"
}

function show_setversion_usage() {
    echo "Usage: $0 versionNumber [-d]"
    echo "   -d        Append date/time to versionNumber"
    die "Invalid arguments"
}

function coffee_done() {
    show_progress "******************************************"
    show_progress "*           COFFEE DONE !                *"
    show_progress "*                                        *"
    show_progress "*  Enjoy your coffee                     *"
    show_progress "*                                        *"
    show_progress "******************************************"
}
