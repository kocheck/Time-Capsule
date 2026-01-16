.PHONY: help setup build test lint clean run archive install

help:
	@echo "Time Capsule Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  setup    - Install dependencies and prepare environment"
	@echo "  build    - Build the application"
	@echo "  test     - Run all tests"
	@echo "  lint     - Run SwiftLint"
	@echo "  clean    - Clean build artifacts"
	@echo "  run      - Build and run the application"
	@echo "  archive  - Create release archive"
	@echo "  install  - Install built app to Applications"

setup:
	@echo "Setting up Time Capsule development environment..."
	@Scripts/setup.sh

build:
	@echo "Building Time Capsule..."
	@xcodebuild build \
		-project TimeCapsule.xcodeproj \
		-scheme TimeCapsule \
		-configuration Debug \
		-destination 'platform=macOS'

test:
	@echo "Running tests..."
	@Scripts/test.sh

lint:
	@echo "Running SwiftLint..."
	@Scripts/lint.sh

clean:
	@echo "Cleaning build artifacts..."
	@xcodebuild clean \
		-project TimeCapsule.xcodeproj \
		-scheme TimeCapsule
	@rm -rf DerivedData
	@rm -rf .build

run: build
	@echo "Running Time Capsule..."
	@open -a ./DerivedData/TimeCapsule/Build/Products/Debug/TimeCapsule.app

archive:
	@echo "Creating release archive..."
	@xcodebuild archive \
		-project TimeCapsule.xcodeproj \
		-scheme TimeCapsule \
		-configuration Release \
		-archivePath ./build/TimeCapsule.xcarchive

install: archive
	@echo "Installing Time Capsule to /Applications..."
	@cp -R ./build/TimeCapsule.xcarchive/Products/Applications/TimeCapsule.app /Applications/

.DEFAULT_GOAL := help
