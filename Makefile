ARCHS = arm64
TARGET := iphone:clang:13.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = NoSandbox
NoSandbox_FILES = src/NoSandbox.xm
NoSandbox_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
NoSandbox_FRAMEWORKS = Foundation UIKit StoreKit
# 纯 ObjC-Runtime 实现，不链接 CydiaSubstrate/ElleKit
NoSandbox_LDFLAGS = -Wno-unused-dylib

include $(THEOS_MAKE_PATH)/library.mk
