#!/usr/bin/env bash

echo "*** $TRAVIS_BRANCH"

if [[ "$TRAVIS_BRANCH" == "stable" ]]
then
    export SCHEME=Release
else
    export SCHEME=Sandbox
fi

echo "*** export $SCHEME"
