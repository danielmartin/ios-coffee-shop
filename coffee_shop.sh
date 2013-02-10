#!/bin/bash
#
# Author: Daniel Martín
# 
# This script downloads the latest version of an iOS app from a repository,
# compiles it and builds an .ipa using the coffee maker script.
# 
# Simply wait until the coffee brews...
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

# Some defaults
pushd `dirname $0` > /dev/null
DEST_DIR=`pwd`
popd > /dev/null
REPO_TYPE="svn"
SDK=iphoneos

# Parse command line
while getopts ":v:p:c:s:ro:bgd:e:la" opt; do
    case $opt in
	v)
	    VERSION_NUMBER="$OPTARG"
	    ;;
	p)
	    PROVISIONING_PROFILE="$OPTARG"
	    ;;
	c)
	    CODE_SIGN_IDENTITY="$OPTARG"
	    ;;
	s)
	    SDK="$OPTARG"
	    ;;
	r)
	    CONFIGURATION="Release"
	    ;;
	o)
	    DEST_DIR="$OPTARG"
	    ;;
	b)
	    REPO_TYPE="svn"
	    ;;
	g)
	    REPO_TYPE="git"
	    ;;
	d)
	    PRODUCT_NAME="$OPTARG"
	    ;;
	e)
	    PROJECT_NAME="$OPTARG"
	    ;;
	l)
	    VALIDATE_IPA="1"
	    ;;
	a)
	    ARCHIVE_IPA="1"
	    ;;
	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    show_coffee_shop_usage
	    ;;
	:)
	    echo "Option -$OPTARG requires an argument." >&2
	    show_coffee_shop_usage
	    ;;
    esac
done

# Options -v and -e are incompatible because of a limitation in Apple's agvtool
if [[ -n "$VERSION_NUMBER" && -n "$PROJECT_NAME" ]]; then
    echo "Options -v and -e are incompatible"
    show_coffee_shop_usage
fi

shift $(( OPTIND -1 ))

# Validate that we received the expected number of arguments
if [ "$#" -lt 1 ]; then
    show_coffee_shop_usage
fi

# Get the project the user wants to compile
REPO_URL="${1}"

# Create a temporary directory
TEMP_DIR=`mktemp -d -t repocheckout`

if [[ "$REPO_TYPE" == svn ]]; then
    svn co $REPO_URL $TEMP_DIR
elif [[ "$REPO_TYPE" == git ]]; then
    git clone $REPO_URL $TEMP_DIR
fi

# Use our coffee maker to build an .ipa
cp setversion.sh common.sh $TEMP_DIR

# Set new version
pushd "$TEMP_DIR" >/dev/null

# Extract the name of the .xcodeproj file. If there is more than one,
# abort the process and encourage the user to execute with the -e switch
projnames=(`find . -name *.xcodeproj 2>/dev/null`)
projnumber=${#projnames[*]}
if [[ $projnumber>1 && -n "$PROJECT_NAME" ]]; then
    for item in ${projnames[*]}
    do
	if [ $(basename "$item" ".xcodeproj")="$PROJECT_NAME" ]; then
	    selectedproject=$(basename "$item" ".xcodeproj")
	    break
	fi
    done
    if [ -z "$selectedproject" ]; then
	echo "The project ${PROJECT_NAME} was not found"
	show_coffe_shop_usage
    fi
elif [[ $projnumber>1 && -z "$PROJECT_NAME" ]]; then
    echo "There is more than one project in the directory, select which one you want to compile with the -e switch."
    show_coffee_shop_usage
elif [[ $projnumber=1 ]]; then
    PROJECT_NAME=$(basename "${projnames[0]}" ".xcodeproj")
    echo "Project name is $PROJECT_NAME"
else
    show_coffee_shop_usage
fi

chmod +x setversion.sh

if [ -z "$CONFIGURATION" ]; then
    CONFIGURATION="Debug"
    if [ -n "$VERSION_NUMBER" ]; then
	./setversion.sh $VERSION_NUMBER -d
	VERSION=$VERSION_NUMBER-`date "+%Y%m%d%H%M%S"`
    fi
else
    if [ -n "$VERSION_NUMBER" ]; then
	./setversion.sh $VERSION_NUMBER
	VERSION=$VERSION_NUMBER
    fi
fi

popd >/dev/null

# Brew our coffee
./coffee_maker.sh "$PROJECT_NAME" "$VERSION" "$PRODUCT_NAME" "$PROVISIONING_PROFILE" "$CODE_SIGN_IDENTITY" "$SDK" "$CONFIGURATION" "$DEST_DIR" "$VALIDATE_IPA" "$ARCHIVE_IPA" "$TEMP_DIR"

