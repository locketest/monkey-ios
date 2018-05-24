#!/usr/bin/env bash

SHELL_DIR=$(cd "$(dirname "$0")"; pwd)    

BUILD_PATH=${SHELL_DIR}/../build/

echo "*** $TRAVIS_BRANCH"

SCHEME_RELEASE=Release
SCHEME_SANDBOX=Sandbox

SANDBOX_IPA_ARCHIVE_PATH=${BUILD_PATH}/${APPNAME}${SCHEME_SANDBOX}
RELEASE_IPA_ARCHIVE_PATH=${BUILD_PATH}/${APPNAME}${SCHEME_RELEASE}

xcodebuild archive -workspace  ${SHELL_DIR}/../${APPNAME}.xcworkspace -scheme ${SCHEME_SANDBOX} -configuration ${SCHEME_SANDBOX} -derivedDataPath ${BUILD_PATH} -archivePath ${SANDBOX_IPA_ARCHIVE_PATH}.xcarchive -quiet

xcodebuild -exportArchive -archivePath ${SANDBOX_IPA_ARCHIVE_PATH}.xcarchive -exportPath ${SANDBOX_IPA_ARCHIVE_PATH} -exportOptionsPlist ${SHELL_DIR}/exportOptions-developer.plist -quiet

xcodebuild archive -workspace  ${SHELL_DIR}/../${APPNAME}.xcworkspace -scheme ${SCHEME_RELEASE} -configuration ${APPNAME} -derivedDataPath ${BUILD_PATH} -archivePath ${RELEASE_IPA_ARCHIVE_PATH}.xcarchive -quiet

xcodebuild -exportArchive -archivePath ${RELEASE_IPA_ARCHIVE_PATH}.xcarchive -exportPath ${RELEASE_IPA_ARCHIVE_PATH} -exportOptionsPlist ${SHELL_DIR}/exportOptions-developer.plist -quiet
