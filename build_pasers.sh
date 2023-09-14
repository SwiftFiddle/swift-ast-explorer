#!/bin/bash

swift build -c release --package-path Resources/parsers/50800
swift build -c release --package-path Resources/parsers/50900
swift build -c release --package-path Resources/parsers/trunk
