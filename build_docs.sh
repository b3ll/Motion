#!/bin/bash

# Parse swift docs.

jazzy --module Motion --swift-build-tool spm --build-tool-arguments -Xswiftc,-sdk,-Xswiftc,"`xcrun --sdk iphonesimulator --show-sdk-path`",-Xswiftc,-target,-Xswiftc,"x86_64-apple-ios13.0-simulator" --author "Adam Bell" --author_url "https://twitter.com/b3ll" --undocumented-text "No overview available." --theme apple --clean

