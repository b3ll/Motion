#!/bin/bash

# Parse swift docs.

jazzy --module Motion --swift-build-tool spm --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5 --author "Adam Bell" --author_url "https://twitter.com/b3ll" --undocumented-text "No overview available." --theme apple --clean
