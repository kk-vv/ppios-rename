#Copyright 2016 PreEmptive Solutions, LLC
#See LICENSE.txt for licensing information

buildDir=build
targetName=BoxSim
configuration=Release
targetAppName="$(buildDir)/Build/Products/$(configuration)-iphoneos/$(targetName).app"

.PHONY: default
default:
	@echo "Usage: make <build|show|clean>"
	@echo ""
	@echo "  buildDir=$(buildDir)"
	@echo "  targetName=$(targetName)"
	@echo "  configuration=$(configuration)"
	@echo "  targetAppName=$(targetAppName)"
	@echo ""
	@exit 1

.PHONY: build
build:
	xcodebuild \
		-project "$(targetName).xcodeproj" \
		-scheme "$(targetName)" \
		-configuration "$(configuration)" \
		-derivedDataPath $(buildDir) \
		clean build

.PHONY: show
show:
	otool -o -v "$(targetAppName)" | grep 'imp 0x' | grep '\[' | awk '{print $$3 " " $$4}' | sort | uniq

.PHONY: clean
clean:
	$(RM) -r $(buildDir) symbols*.h symbols*.map excludes-*.list
