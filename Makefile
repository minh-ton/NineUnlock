# If you want to test the tweak on iOS Simulator, set
# SIMULATOR = 1 and execute 'make setup'. Make sure that
# your simulator is turned on before using the command.

# When building for a normal iOS Device, set
# SIMULATOR = 0 and execute 'make package install'

# Also change SIMULATOR = YES in Tweak.xm when compiling
# for iOS Simulators

# MAKE SURE THAT THE SIMULATOR HAS ALREADY RUNNING!

SIMULATOR=0

ifeq ($(SIMULATOR),1)
TARGET = simulator:clang::7.0
ARCHS = x86_64 i386
DEBUG = 0
else
TARGET := iphone:clang:latest:7.0
ARCHS = arm64 arm64e
DEBUG = 0
endif

PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NineUnlock
$(TWEAK_NAME)_LIBRARIES = colorpicker

NineUnlock_FILES = Tweak.xm
NineUnlock_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

ifneq (,$(filter x86_64 i386,$(ARCHS)))
setup:: clean all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@codesign -f -s - /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
	@resim
endif
SUBPROJECTS += nineunlockpref
include $(THEOS_MAKE_PATH)/aggregate.mk
