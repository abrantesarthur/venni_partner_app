FLUTTER ?= flutter
FLUTTERRUN ?= $(FLUTTER) run

# load environment variabels
include .env
export

################################################################################
## Config
################################################################################

check-dev-env:
ifndef DEV_GOOGLE_MAPS_API_KEY
	$(error DEV_GOOGLE_MAPS_API_KEY is undefined)
endif
# used to send requests from physycal device to firebase emulator suite
ifndef HOST_IP_ADDRESS
	$(error HOST_IP_ADDRESS is undefined)
endif

check-env:
ifndef IOS_GOOGLE_MAPS_API_KEY
	$(error GOOGLE_MAPS_API_KEY is undefined)
endif
ifndef ANDROID_GOOGLE_MAPS_API_KEY
	$(error GOOGLE_MAPS_API_KEY is undefined)
endif



################################################################################
## Main make targets
################################################################################
.PHONY: rundev
rundev: check-dev-env
# build and run the app in Development mode
# --flavor dev determines which Android productFlavors or iOS Schema to pick when building the app
# --dart-define provives environment variables at both native flutter level. Extracting the values
# differs for Android and iOS. In Android, we modify app level build.gradle to extract values
# using project.property('dart-defines'). Then, we set a defaultConfig's resValue with the variable's value.
# In iOS, the variables are available through the DART_DEFINES environment variable, which we can use
# in the Info.Plist file to set a new key. This key, like all other keys in Info.plist, is available
# in AppDelegate.swift with Bundle.main.infoDictionary.
# -t lib/main defines the build entrypoint.
	$(FLUTTERRUN) \
	-v \
	--flavor dev \
	--dart-define=DEV_ANDROID_GOOGLE_MAPS_API_KEY=$(DEV_ANDROID_GOOGLE_MAPS_API_KEY) \
	--dart-define=DEV_IOS_GOOGLE_MAPS_API_KEY=$(DEV_IOS_GOOGLE_MAPS_API_KEY) \
	-t lib/main_dev.dart

.PHONY: run
run: check-env
	$(FLUTTERRUN) \
	--flavor prod \
	--dart-define=IOS_GOOGLE_MAPS_API_KEY=$(IOS_GOOGLE_MAPS_API_KEY) \
	--dart-define=ANDROID_GOOGLE_MAPS_API_KEY=$(ANDROID_GOOGLE_MAPS_API_KEY) \
	-t lib/main.dart

################################################################################
## test targets
################################################################################

.PHONY: unit_test
unit_test:
	flutter test --name=test/unit/* --coverage
	
.PHONY: widget_test
widget_test:
	flutter test --name=test/widget/* --coverage

.PHONY: integration_test
integration_test:
	flutter test --name=test/integration/* --coverage