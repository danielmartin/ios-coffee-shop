#!/bin/bash
#
# Author: Daniel Martín
# 
# This script sets a given product version to an iOS Xcode project
# using the agvtool command line tool.
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

. $(dirname $0)/common.sh

if [ "$#" -ne 1 ] && [ "$#" -ne 2 ]; then
    show_setversion_usage
fi

# Get current revision from repo
if [ "$#" -eq 1 ]; then
	version=$1
else
	if [ "$2" == "-d" ]; then
		version=$1-`date "+%Y%m%d%H%M%S"`
	else
	    show_setversion_usage
	fi
fi

show_progress "Setting evermeeting project to version $version..."
agvtool new-version -all $version > /dev/null
agvtool new-marketing-version $version > /dev/null
show_progress "Project version modified successfully"
