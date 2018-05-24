#!/usr/bin/env bash

SHELL_DIR=$(cd "$(dirname "$0")"; pwd)

pushd ${SHELL_DIR}

SCHEME_SANDBOX=Sandbox

security delete-keychain ios-build.keychain
rm -f ~/Library/MobileDevice/Provisioning\ Profiles/${SCHEME_SANDBOX}.mobileprovision

popd
