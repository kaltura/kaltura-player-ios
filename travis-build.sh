#!/bin/bash

set -eou pipefail

# Travis aborts the build if it doesn't get output for 10 minutes.
keepAlive() {
  while [ -f $1 ]
  do 
    sleep 10
    echo .
  done
}

buildiOSApp() {
  echo Building the iOS TestApp
  cd iOSTestApp
  pod install
  CODE=0
  xcodebuild clean build -workspace iOSTestApp.xcworkspace -scheme iOSTestApp ONLY_ACTIVE_ARCH=NO -destination 'platform=iOS Simulator,name=iPhone 11' | tee xcodebuild.log | xcpretty -r html || CODE=$?
  cd ../
  export CODE
}

buildtvOSApp() {
  echo Building the tvOS TestApp
  cd tvOSTestApp
  pod install
  CODE=0
  xcodebuild clean build -workspace tvOSTestApp.xcworkspace -scheme tvOSTestApp ONLY_ACTIVE_ARCH=NO -destination 'platform=tvOS Simulator,name=Apple TV' | tee xcodebuild.log | xcpretty -r html || CODE=$?
  cd ../
  export CODE
}

libLint() {
  echo Linting the pod
  pod lib lint --fail-fast --allow-warnings
}


FLAG=$(mktemp)

if [ -n "$TRAVIS_TAG" ] || [ "$TRAVIS_EVENT_TYPE" == "cron" ]; then
  keepAlive $FLAG &
  libLint
else
  buildiOSApp
  buildtvOSApp
fi

rm $FLAG  # stop keepAlive
