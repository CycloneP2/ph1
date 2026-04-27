export TARGET = iphone:clang:latest:11.0
export ARCHS = arm64

INSTALL_TARGET_PROCESSES = MobileMLBB

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EdgyHacks

# Source files
EdgyHacks_FILES = Edgy.mm
EdgyHacks_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore
EdgyHacks_OBJCCFLAGS = -std=c++11
ADDITIONAL_OBJCCFLAGS = -std=c++11
EdgyHacks_CFLAGS = -fobjc-arc

# Handle Sideload flag
ifeq ($(NON_JAILBREAK),1)
EdgyHacks_CFLAGS += -DNON_JAILBREAK=1
endif

include $(THEOS)/makefiles/tweak.mk
