include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ControlPlz
ControlPlz_FILES = Tweak.xm
ControlPlz_LIBRARIES = applist
controlplz_EXTRA_FRAMEWORKS += Cephei


include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += controlplz
include $(THEOS_MAKE_PATH)/aggregate.mk
