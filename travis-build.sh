#!/bin/bash

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
  xcodebuild clean build -workspace iOSTestApp.xcworkspace -scheme iOSTestApp ONLY_ACTIVE_ARCH=NO -destination 'platform=iOS Simulator,name=iPhone 11' | tee xcodebuild.log | xcpretty -r html && exit ${PIPESTATUS[0]}
  cd ../
}

buildtvOSApp() {
  echo Building the tvOS TestApp
  cd tvOSTestApp
  pod install
  xcodebuild clean build -workspace tvOSTestApp.xcworkspace -scheme tvOSTestApp ONLY_ACTIVE_ARCH=NO -destination 'platform=tvOS Simulator,name=Apple TV' | tee xcodebuild.log | xcpretty -r html && exit ${PIPESTATUS[0]}
  cd ../
}

libLint() {
  echo Linting the pod
  pod lib lint --allow-warnings
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
