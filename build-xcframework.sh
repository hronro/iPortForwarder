#!/bin/sh

BASEDIR=$(dirname "$0")

cd $BASEDIR

rm -rf ui/iPortForwarder/Libipf/Ipf.xcframework

sh core/build-macos-universal-libs.sh

xcodebuild -create-xcframework -library core/target/universal-apple-darwin/release/libipf.a -headers core/headers -output ui/iPortForwarder/Libipf/Ipf.xcframework
