#!/bin/sh

SHELL_DIR=$(cd "$(dirname "$0")"; pwd)

BUILD_PATH=${SHELL_DIR}/../build/

msg=$(git log -1 --pretty=%s%b)

SCHEME_RELEASE=Release
SCHEME_SANDBOX=Sandbox

echo "commit msg: ${msg}"

if [ ! -z "$FIR_APP_TOKEN" ]; then

    echo ""
    echo "***************************"
    echo "*   Uploading to Fir.im   *"
    echo "***************************"
    echo ""

    fir p ${BUILD_PATH}/${APPNAME}${SCHEME_SANDBOX}/${SCHEME_SANDBOX}.ipa -T $FIR_APP_TOKEN -c "${SCHEME_SANDBOX} - ${msg}"
    fir p ${BUILD_PATH}/${APPNAME}${SCHEME_RELEASE}/${SCHEME_RELEASE}.ipa -T $FIR_APP_TOKEN -c "${SCHEME_RELEASE} - ${msg}"
fi
