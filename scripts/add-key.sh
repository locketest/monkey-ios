#!/usr/bin/env bash

SHELL_DIR=$(cd "$(dirname "$0")"; pwd)

pushd ${SHELL_DIR}

SCHEME_SANDBOX=Sandbox
KEYCHAIN_PASSWORD=travis

#echo "*** $TRAVIS_BRANCH"

openssl aes-256-cbc -k $ENCRYPTION_SECRET -in certs/${SCHEME_SANDBOX}.cer.enc -d -a -out certs/${SCHEME_SANDBOX}.cer
openssl aes-256-cbc -k $ENCRYPTION_SECRET -in certs/${SCHEME_SANDBOX}.p12.enc -d -a -out certs/${SCHEME_SANDBOX}.p12

security -v create-keychain -p ${KEYCHAIN_PASSWORD} ios-build.keychain
security -v default-keychain -s ios-build.keychain
security -v unlock-keychain -p ${KEYCHAIN_PASSWORD} ios-build.keychain
security -v set-keychain-settings -t 864000 -lu ~/Library/Keychains/ios-build.keychain
security -v import certs/${SCHEME_SANDBOX}.cer -k ~/Library/Keychains/ios-build.keychain -T /usr/bin/codesign
security -v import certs/${SCHEME_SANDBOX}.p12 -k ~/Library/Keychains/ios-build.keychain -P "${KEY_PASSWORD}" -T /usr/bin/codesign
security -v set-key-partition-list -S apple-tool:,apple:,codesign: -s -k ${KEYCHAIN_PASSWORD} ios-build.keychain
mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles

for file in profile/*.mobileprovision.enc; do
    provision_file=${file/.enc/}
    openssl aes-256-cbc -k $ENCRYPTION_SECRET -in $file -d -a -out ${provision_file}
    final_file=`grep UUID -A1 -a "$provision_file" | grep -io "[-A-F0-9]\{36\}"`
    echo "$file -> $final_file"
    mv -f $provision_file ~/Library/MobileDevice/Provisioning\ Profiles/${final_file}.mobileprovision
done
security -v find-identity -p codesigning ~/Library/Keychains/ios-build.keychain
security -v list-keychains

popd
