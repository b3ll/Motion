#!/bin/bash

swift package --allow-writing-to-directory docs generate-documentation --target Motion --disable-indexing --transform-for-static-hosting --hosting-base-path Motion --output-path docs
swift package --disable-sandbox preview-documentation --target Motion
