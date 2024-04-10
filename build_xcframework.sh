#!/bin/bash

pushd "$( dirname -- "$0"; )"

rm -rf build/output
rm -rf Motion.zip

mkdir -p build

git clone https://github.com/giginet/Scipio.git build/scipio

pushd build/scipio

swift run -c release scipio create ../../ --enable-library-evolution --support-simulators --only-use-versions-from-resolved-file --output ../output 

zip -r ../../Motion.zip ../output/Motion.xcframework

popd
popd
