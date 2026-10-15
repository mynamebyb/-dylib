ARCHS = arm64
TARGET := iphone:clang
SDKVERSION = latest
IPHONEOS_DEPLOYMENT_TARGET = 13.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = NoSandbox
NoSandbox_FILES = src/NoSandbox.xm
NoSandbox_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
NoSandbox_FRAMEWORKS = Foundation UIKit StoreKit
NoSandbox_LDFLAGS = -Wno-unused-dylib

include $(THEOS_MAKE_PATH)/library.mk
