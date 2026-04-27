export TARGET = iphone:clang:latest:11.0
export ARCHS = arm64

INSTALL_TARGET_PROCESSES = MobileMLBB

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EdgyHacks

# Source files
EdgyHacks_FILES = Tweak.mm
EdgyHacks_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
EdgyHacks_CFLAGS = -fobjc-arc

# Handle Sideload flag
ifeq ($(NON_JAILBREAK),1)
EdgyHacks_CFLAGS += -DNON_JAILBREAK=1
# Link Titanox if available in the same directory or standard include
EdgyHacks_LDFLAGS = -L./Titanox -ltitanox
EdgyHacks_CFLAGS += -I./Titanox
endif

include $(THEOS)/makefiles/tweak.mk
