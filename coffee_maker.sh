#!/bin/bash
#
# Author: Daniel Martín
# 
# This script builds the code downloaded from repository, creates and signs an .ipa
# file using the developer profile and provisioning profile, and performs a validation
# step to ensure the binary is ready for App Store submission. For convenience, symbol 
# files are archived to a new folder in the user's home directory to facilitate debugging.
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

if [ "$#" -lt 11 ]; then
    show_coffee_maker_usage
fi

PROJECT_NAME="${1}"
BUILD_NUMBER="${2}"
IPA_FINAL_PRODUCT_NAME="${3}"
PROFILE_UUID="${4}"
CODE_SIGN_IDENTITY="${5}"
SDK="${6}"
CONFIGURATION="${7}"
DEST_DIR="${8}"
VALIDATE_IPA="${9}"
ARCHIVE_IPA="${10}"
APP_NAME="$PROJECT_NAME".app
TEMP_DIR="${11}"

# Change to temporary directory
pushd "$TEMP_DIR" >/dev/null

if [ -z "$IPA_FINAL_PRODUCT_NAME" ]; then
    IPA_FINAL_PRODUCT_NAME="$PROJECT_NAME"
fi

OUTPUT_DIR=`mktemp -d -t ${PROJECT_NAME}-inhouse`
RESULTS_DIR="$OUTPUT_DIR"/"$CONFIGURATION"-"$SDK"

test -n "$XCODEBUILD" || XCODEBUILD=`which xcodebuild` 
if [ ! -x "$XCODEBUILD" ]; then 
	# Check if xcodebuild is in path. If not, bail out
    XCODEBUILD=/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild
    test -x "$XCODEBUILD" || die "Could not find xcodebuild in $PATH"
fi

#----------------------------------------------------------------
# Build code
#
function xcode_build_app() {
    show_progress "Building app..."
    if [[ "$SDK" == "iphoneos" ]]; then
	ARCH="armv7"
    else
	ARCH="i386"
    fi

    XCODE_CMD="  -alltargets \
                 -sdk $SDK \
                 -configuration $CONFIGURATION \
                 -arch $ARCH \
                 SYMROOT=$OUTPUT_DIR \
                 OBJROOT=$OUTPUT_DIR \
                 clean build"

    [ -n "$PROJECT_NAME" ] && XCODE_CMD="${XCODE_CMD}"" -project $PROJECT_NAME.xcodeproj"
    [ -n "$CODE_SIGN_IDENTITY" ] && XCODE_CMD="${XCODE_CMD}"" CODE_SIGN_IDENTITY=\"$CODE_SIGN_IDENTITY\""
    [ -n "$PROFILE_UUID" ] && XCODE_CMD="${XCODE_CMD}"" PROVISIONING_PROFILE=$PROFILE_UUID"

    XCODE_CMD="$XCODEBUILD""${XCODE_CMD}"
    echo $XCODE_CMD

    eval $XCODE_CMD || die "Couldn't build project. Coffee maker stops."
}

#----------------------------------------------------------------
# Build .ipa pockage
#
function build_app_ipa() {
    show_progress "Building .ipa... The coffee is almost done."
    PACKAGE_DIR=`mktemp -d -t ${PROJECT_NAME}-inhouse-pkg`

    pushd "$PACKAGE_DIR" >/dev/null
    PAYLOAD_DIR="Payload"
    mkdir "$PAYLOAD_DIR"
    cp -a "$RESULTS_DIR"/"$APP_NAME" "$PAYLOAD_DIR"
    rm -f "$IPA_FINAL_PRODUCT_NAME".ipa
    zip -y -r "$IPA_FINAL_PRODUCT_NAME".ipa "$PAYLOAD_DIR" 
    show_progress ...Package at: "$PACKAGE_DIR"/"$IPA_FINAL_PRODUCT_NAME".ipa
	# Generate a unique name using version number and timestamp
    if [ -z "$BUILD_NUMBER" ]; then
	IPA_FINAL_PRODUCT_NAME_TIMESTAMP="$IPA_FINAL_PRODUCT_NAME".ipa
    else
	IPA_FINAL_PRODUCT_NAME_TIMESTAMP="$IPA_FINAL_PRODUCT_NAME"_"$BUILD_NUMBER".ipa
    fi
	# Copy to destination folder
    cp "$PACKAGE_DIR"/"$IPA_FINAL_PRODUCT_NAME".ipa "$DEST_DIR"/"$IPA_FINAL_PRODUCT_NAME_TIMESTAMP"
}

#----------------------------------------------------------------
# Validate .ipa package 
#
function validate_app_ipa() {
    show_progress "Validating .ipa..."

	# Apple's Validation tool exits with error code 0 even on error, so we have to search the output.
    VALIDATION_TOOL="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/Validation"
    VALIDATION_RESULT=`"$VALIDATION_TOOL" -verbose -errors "$IPA_FINAL_PRODUCT_NAME".ipa`
    if [[ "$VALIDATION_RESULT" == *error:* ]]; then
    	echo "Validation failed: $VALIDATION_RESULT"
    	exit 1
    fi
    show_progress ".ipa validated successfully"
    popd >/dev/null
}

#----------------------------------------------------------------
# Archive .ipa and debugging symbols 
#
function archive_app_ipa() {
    show_progress "Archiving .ipa..."
    if [ -z "$BUILD_NUMBER" ]; then
	BUILD_ARCHIVE_DIR=~/iossdkarchive/"$PROJECT_NAME"
    else
	BUILD_ARCHIVE_DIR=~/iossdkarchive/"$PROJECT_NAME"/"$BUILD_NUMBER"
    fi
    mkdir -p "$BUILD_ARCHIVE_DIR"

    pushd "$RESULTS_DIR" >/dev/null
    if [ -z "$BUILD_NUMBER" ]; then
	ARCHIVE_PATH="$BUILD_ARCHIVE_DIR"/Archive.zip
    else
	ARCHIVE_PATH="$BUILD_ARCHIVE_DIR"/Archive-"$BUILD_NUMBER".zip
    fi
    zip -y -r "$ARCHIVE_PATH" "$APP_NAME" "$APP_NAME".dSYM
    show_progress ...Archive at: "$ARCHIVE_PATH"
    
    popd >/dev/null
}

function delete_temporaries() {
    popd >/dev/null
    rm -rf "$TEMP_DIR"
    rm -rf "$OUTPUT_DIR"
    rm -rf "$PACKAGE_DIR"
}

xcode_build_app
build_app_ipa
if [ -n "$VALIDATE_IPA" ]; then
    validate_app_ipa 
fi
if [ -n "$ARCHIVE_IPA" ]; then
    archive_app_ipa
fi
coffee_done
delete_temporaries
