#!/bin/sh

set -x -o pipefail

if [[ "$SWIFT_BUILD" == "true" ]]; then
    swift build
    exit 0
fi

# -jobs -- specify the number of concurrent jobs
# `sysctl -n hw.ncpu` -- fetch number of 'logical' cores in macOS machine
xcodebuild -jobs `sysctl -n hw.ncpu` test -project DVR.xcodeproj -scheme ${TRAVIS_XCODE_SCHEME} -sdk ${TRAVIS_XCODE_SDK} \
  -destination "platform=${DESTINATION}" ONLY_ACTIVE_ARCH=YES CODE_SIGNING_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcpretty -c

