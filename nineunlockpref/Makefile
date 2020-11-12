TARGET := iphone:clang:latest:7.0
SDKVERSION = 11.2
SYSROOT = $(THEOS)/sdks/iPhoneOS11.2.sdk
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = NineUnlockPref

NineUnlockPref_FILES = NineUnlockRootListController.m NineUnlockRootHeaderView.m
NineUnlockPref_FRAMEWORKS = UIKit
NineUnlockPref_PRIVATE_FRAMEWORKS = Preferences
NineUnlockPref_INSTALL_PATH = /Library/PreferenceBundles
NineUnlockPref_CFLAGS = -fobjc-arc
NineUnlockPref_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk
