ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = FreeFire

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SharkTool
SharkTool_FILES = GameUtils.mm Menu.mm ESP.mm Aimbot.mm
SharkTool_FILES += imgui/imgui.cpp imgui/imgui_draw.cpp imgui/imgui_tables.cpp imgui/imgui_widgets.cpp
SharkTool_FILES += imgui/backends/imgui_impl_metal.mm
SharkTool_CFLAGS = -fobjc-arc -std=c++17 -Iimgui -Iimgui/backends -w
SharkTool_FRAMEWORKS = UIKit Foundation Metal MetalKit QuartzCore
SharkTool_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/tweak.mk
