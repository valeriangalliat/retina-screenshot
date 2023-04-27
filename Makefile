SOURCES = $(shell find Sources -name '*.swift')

all: retina-screenshot
	
retina-screenshot: $(SOURCES)
	swift build
	mv .build/debug/retina-screenshot .

lint:
	swiftlint Sources

analyze: xcodebuild.log
	swiftlint analyze --compiler-log-path xcodebuild.log

analyze-fix: xcodebuild.log
	swiftlint analyze --compiler-log-path xcodebuild.log --fix

# We don't use `xcodebuild` but SwiftLint needs a `xcodebuild` log file to
# work, but we can generate a similar file from `swift build -v`. We need the
# full `swiftc` command that includes `-module-name`.
#
# See <https://github.com/realm/SwiftLint/blob/73acbaf6d57f387adedece0b5569a9d6be9aa413/Source/swiftlint/Helpers/CompilerArgumentsExtractor.swift#L7>.
#
# We `touch` the file in order to make sure `swift build` compiles at least
# one file, so that we can harvest the full build command from the debug output.
xcodebuild.log:
	touch Sources/main.swift
	swift build -v | grep 'module-name retina_screenshot' > $@
