include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = controlplz
controlplz_FILES = CPZRootListController.m
controlplz_INSTALL_PATH = /Library/PreferenceBundles
controlplz_FRAMEWORKS = UIKit
controlplz_EXTRA_FRAMEWORKS += CepheiPrefs
controlplz_LIBRARIES = applist
controlplz_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/controlplz.plist$(ECHO_END)
