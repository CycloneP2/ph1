export TARGET = iphone:clang:latest:11.0
export ARCHS = arm64

export ADDITIONAL_OBJCFLAGS = -fobjc-arc -O2

INSTALL_TARGET_PROCESSES = MobileMLBB

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EdgyHacks

# Source files
EdgyHacks_FILES = Tweak.mm

# Frameworks (hanya default iOS)
EdgyHacks_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore

# Flag buat final package (kecilin ukuran)
DEBUG = 0
FINALPACKAGE = 1

# Optional: matiin warning yang gak penting
EdgyHacks_CFLAGS = -Wno-deprecated-declarations

include $(THEOS)/makefiles/tweak.mk
