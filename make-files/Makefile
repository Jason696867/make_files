# Medtronic MITG R&D
# 5920 Longbow Drive, Boulder, CO
# Copyright (c) 2016 Medtronic
# All Rights Reserved.
#
# @file  Makefile
#
# Build the apps, run tests, deploy to target, analyze source code,
# and install developer toolbox.
#
# The toolbox includes standards-enforcement and documentation tools.

usage:
	@echo "Usage: make (apps|docs|toolbox)"

clean:
	@echo "Usage: make (clean-apps|clean-docs|clean-toolbox)"

.PHONY: usage clean

GIT_SHA=$(shell git rev-parse HEAD)
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
GIT_SPOT=$(shell git describe --tags --always --dirty)
GIT_VERSION="$(GIT_BRANCH)/$(GIT_SPOT)"
GIT_TAG=$(shell git describe --tags --abbrev=0)
ifneq ("$(wildcard deliverables/version.txt)","")
  SOFTWARE_VERSION=$(shell cat deliverables/version.txt)
else
  SOFTWARE_VERSION=$(shell cat deliverables/IB-version.txt)
endif

RSYNC=rsync --recursive --checksum --perms --quiet

# Location of metrics data.
METRICS_DIR=$(HOME)/metrics

# Require a specific version of Qt.

QT_VERSION=5.5
QT_REVISION=$(QT_VERSION).1

QMAKE=qmake
TOOLCHAIN=/opt/rfs200-arm-crosstool-chain
TARGET_QMAKE=$(TOOLCHAIN)/usr/bin/$(QMAKE)

# Treat compiler warnings as errors.
WARNINGS_ARE_ERRORS="QMAKE_CXXFLAGS += -Werror -fno-strict-overflow" "QMAKE_CFLAGS += -Werror"

# Pass version information to the C++ code.
COMPILED_VERSION=DEFINES+=GIT_VERSION='"$(GIT_VERSION)"' DEFINES+=SOFTWARE_VERSION='"$(SOFTWARE_VERSION)"'

# If instrumentation is requested, adjust compilation for code coverage analysis using gcov.
ifdef INSTRUMENTED
QMAKE_OPTIONS="QMAKE_CXXFLAGS += --coverage" "QMAKE_LFLAGS += --coverage"
DEBUG=0
else
QMAKE_OPTIONS=
endif

# If DEBUG is set to 1, let qmake know.
ifeq ($(DEBUG),1)
QMAKE_DEBUG_SWITCH="CONFIG+=debug" "DEFINES += DEBUG=1"
else
QMAKE_DEBUG_SWITCH="CONFIG+=release"
endif

VM_QMAKE_OPTIONS="DEFINES+=SIMULATE" $(QMAKE_OPTIONS) $(QMAKE_DEBUG_SWITCH) $(WARNINGS_ARE_ERRORS) $(COMPILED_VERSION)
TARGET_QMAKE_OPTIONS="FOR_TARGET=1" "DEFINES+=TARGET" $(QMAKE_OPTIONS) $(QMAKE_DEBUG_SWITCH) $(WARNINGS_ARE_ERRORS) $(COMPILED_VERSION)

QMAKE_VERSION := $(shell $(QMAKE) --version |awk '/Qt version/ {print $$4}' |cut -c1-3)
TARGET_QMAKE_VERSION := $(shell $(TARGET_QMAKE) --version |awk '/Qt version/ {print $$4}' |cut -c1-3)

ifneq ("$(QMAKE_VERSION)", "$(QT_VERSION)")
  $(warning "Expected Qt version $(QT_VERSION) found $(QMAKE_VERSION)")
endif

ifneq ("$(TARGET_QMAKE_VERSION)", "$(QT_VERSION)")
  $(warning "Expected toolchain Qt version $(QT_VERSION) found $(TARGET_QMAKE_VERSION)")
endif


# Build the apps.

BUILD_DIR=build

clean-apps:
	rm -rf $(BUILD_DIR)
	rm -rf swqa/testdriver/build

.PHONY: clean-apps

VM_BUILD_DIR=$(BUILD_DIR)/vm-apps
VM_DIST_DIR=$(VM_BUILD_DIR)/bin

TARGET_BUILD_DIR=$(BUILD_DIR)/target-apps
TARGET_DIST_DIR=$(TARGET_BUILD_DIR)/bin
TARGET_VARLOG_DIR=$(TARGET_BUILD_DIR)/var/log

APPS=$(sort $(foreach dir, $(dir $(wildcard */*.pro)), $(dir:/=)))

VM_APP_DIST=$(foreach dir, $(APPS), $(VM_DIST_DIR)/$(dir))
VM_APP_BINS=$(foreach dir, $(APPS), $(VM_BUILD_DIR)/$(dir)/$(dir))
VM_APP_MAKEFILES=$(foreach dir, $(APPS), $(VM_BUILD_DIR)/$(dir)/Makefile)

TARGET_APP_DIST=$(foreach dir, $(APPS), $(TARGET_DIST_DIR)/$(dir))
TARGET_APP_BINS=$(foreach dir, $(APPS), $(TARGET_BUILD_DIR)/$(dir)/$(dir))
TARGET_APP_MAKEFILES=$(foreach dir, $(APPS), $(TARGET_BUILD_DIR)/$(dir)/Makefile)

VM_APP_ASSETS=$(VM_BUILD_DIR)/assets
TARGET_APP_ASSETS=$(TARGET_BUILD_DIR)/assets

LAUNCH_CONFIG=launchConfig.xml
VM_LAUNCH_CONFIG=$(VM_DIST_DIR)/$(LAUNCH_CONFIG)
TARGET_LAUNCH_CONFIG=$(TARGET_DIST_DIR)/$(LAUNCH_CONFIG)

$(warning "MAKE is:  '$(MAKE)' set by $(origin MAKE)")

$(TOOLCHAIN):
	$(MAKE) -C crossdevelop cross-toolchain

apps: vm-apps target-apps

# We want to force recursive make, so each app recompiles if its
# own source changes.
FORCE:

vm-apps: $(VM_APP_DIST) $(VM_APP_ASSETS) $(VM_LAUNCH_CONFIG)

.SECONDEXPANSION:
$(VM_APP_DIST): $(VM_BUILD_DIR)/$$(@F)/$$(@F)
	@mkdir -p $(@D)
	cp -p $^ $@

.SECONDEXPANSION:
$(VM_APP_BINS): $$(@D)/Makefile FORCE
	$(MAKE) -C $(@D)

# Build app Makefile from the .pro file managed by Qt Creator.
.SECONDEXPANSION:
$(VM_APP_MAKEFILES): $$(subst $(VM_BUILD_DIR)/,,$$(@D)/$$(@D).pro)
	@mkdir -p $(@D)
	cd $(@D) && $(QMAKE) $(VM_QMAKE_OPTIONS) ../../../$^

target-apps: $(TOOLCHAIN) $(TARGET_APP_DIST) $(TARGET_APP_ASSETS) $(TARGET_LAUNCH_CONFIG)

.SECONDEXPANSION:
$(TARGET_APP_DIST): $(TARGET_BUILD_DIR)/$$(@F)/$$(@F)
	@mkdir -p $(@D)
	cp -p $^ $@

.SECONDEXPANSION:
$(TARGET_APP_BINS): $$(@D)/Makefile FORCE
	$(MAKE) -C $(@D)

# Build app Makefile from the .pro file managed by Qt Creator.
.SECONDEXPANSION:
$(TARGET_APP_MAKEFILES): $$(subst $(TARGET_BUILD_DIR)/,,$$(@D)/$$(@D).pro)
	@mkdir -p $(@D)
	cd $(@D) && $(TARGET_QMAKE) $(TARGET_QMAKE_OPTIONS) ../../../$^

.PHONY: apps vm-apps target-apps


# Copy the assets.

$(VM_APP_ASSETS):
	@mkdir -p $(@D)
	$(RSYNC) --delete assets/ $@
	$(RSYNC) test-assets/ $@
	@mkdir -p $@/translations
	cd view && lrelease -silent view.pro
	mv view/translations/*.qm $@/translations

$(TARGET_APP_ASSETS):
	@mkdir -p $(@D)
	$(RSYNC) --delete assets/ $@
	$(RSYNC) test-assets/ $@
	@mkdir -p $@/translations
	cd view && lrelease -silent view.pro
	mv view/translations/*.qm $@/translations

.PHONY: $(VM_APP_ASSETS) $(TARGET_APP_ASSETS)


# Build applauncher configuration file.

GENERATE_LAUNCH_CONFIG=bin/generate_launch_config.py

PYTHON3=/usr/bin/python3

$(PYTHON3):
	sudo apt-get install python3

$(VM_LAUNCH_CONFIG): $(VM_APP_DIST) $(PYTHON3)
	$(GENERATE_LAUNCH_CONFIG) $(@D) $(APPS) >$@

$(TARGET_LAUNCH_CONFIG): $(TARGET_APP_DIST) $(PYTHON3)
	$(GENERATE_LAUNCH_CONFIG) $(@D) $(APPS) >$@


# Build and run tests.

TESTDRIVER=swqa/bin/testdriver

VM_TEST_BUILD_DIR=$(BUILD_DIR)/vm-tests

TARGET_TEST_BUILD_DIR=$(BUILD_DIR)/target-tests

UNIT_TESTS=$(foreach dir, $(dir $(wildcard */test/*/*.pro)), $(dir:/=))

VM_UNIT_TEST_BINS=$(foreach dir, $(UNIT_TESTS), $(VM_TEST_BUILD_DIR)/$(dir)/$(notdir $(dir)))
VM_UNIT_TEST_MAKEFILES=$(foreach dir, $(UNIT_TESTS), $(VM_TEST_BUILD_DIR)/$(dir)/Makefile)
VM_UNIT_TEST_REPORTS=$(foreach dir, $(UNIT_TESTS), $(VM_TEST_BUILD_DIR)/$(subst /test/,/test-reports,$(dir $(dir)))/$(notdir $(dir)).xml)

TARGET_UNIT_TEST_BINS=$(foreach dir, $(UNIT_TESTS), $(TARGET_TEST_BUILD_DIR)/$(dir)/$(notdir $(dir)))
TARGET_UNIT_TEST_MAKEFILES=$(foreach dir, $(UNIT_TESTS), $(TARGET_TEST_BUILD_DIR)/$(dir)/Makefile)

vm-unit-tests: $(VM_UNIT_TEST_REPORTS)

.SECONDEXPANSION:
$(VM_UNIT_TEST_BINS): $$(@D)/Makefile FORCE
	$(MAKE) -C $(@D)

# Build each test app Makefile from the .pro file managed by Qt Creator.
.SECONDEXPANSION:
$(VM_UNIT_TEST_MAKEFILES): $$(subst $(VM_TEST_BUILD_DIR)/,,$$(@D)/$$(notdir $$(@D)).pro)
	@mkdir -p $(@D)
	cd $(@D) && $(QMAKE) $(VM_QMAKE_OPTIONS) ../../../../../$^

.SECONDEXPANSION:
$(VM_UNIT_TEST_REPORTS): $$(basename $$(subst /test-reports/,/test/,$$(@D)/$$(@F)))/$$(basename $$(@F))
	@mkdir -p $(@D)
	$^ -o $@,xunitxml

vm-functional-tests: $(TESTDRIVER) vm-apps
	swqa/bin/test_all_consoles vm functional $(CONSOLE)

# Note: compiles but does not run the target unit tests, unlike vm-unit-tests.
target-unit-tests: $(TARGET_UNIT_TEST_BINS)

.SECONDEXPANSION:
$(TARGET_UNIT_TEST_BINS): $$(@D)/Makefile FORCE
	$(MAKE) -C $(@D)

# Build each test app Makefile from the .pro file managed by Qt Creator.
.SECONDEXPANSION:
$(TARGET_UNIT_TEST_MAKEFILES): $$(subst $(TARGET_TEST_BUILD_DIR)/,,$$(@D)/$$(notdir $$(@D)).pro)
	@mkdir -p $(@D)
	cd $(@D) && $(TARGET_QMAKE) $(TARGET_QMAKE_OPTIONS) ../../../../../$^

target-functional-tests: $(TESTDRIVER) deploy-target-apps
	swqa/bin/test_all_consoles target functional $(CONSOLE)

.PHONY: vm-unit-tests vm-functional-tests target-unit-tests target-functional-tests


$(TESTDRIVER): swqa/testdriver/build/testdriver
	cp -p $^ $@

swqa/testdriver/build/testdriver: swqa/testdriver/CMakeLists.txt swqa/testdriver/main.cpp
	mkdir -p $(@D)
	cd $(@D) && cmake -DGTEST_ROOT="/usr/local/src/googletest/" ..
	$(MAKE) -C $(@D)

# VM smoke tests in Continuous Integration use a virtual framebuffer since running in headless mode.
ci-smoke-vm-tests: $(TESTDRIVER) vm-apps
	xvfb-run --error-file=/dev/stdout --server-args="-screen 0 640x480x16" swqa/bin/test_all_consoles vm smoke

# Target power-cycle testing, with 3-second delay to power off after successful boot.
# The number of repetitions can be set as environment variable REPETITIONS (default 1).
REPETITIONS?=1
target-power-tests:
	$(MAKE) clean-target-logs
	for n in $$(seq $(REPETITIONS)); do \
		REPETITION=$$n swqa/bin/cycle_all_consoles target 3 $(CONSOLE); \
	done
	$(MAKE) save-target-logs

# Target functional tests in Nightly Build save the app log files as artifact.
nb-functional-target-tests: $(TESTDRIVER) deploy-target-apps
	$(MAKE) clean-target-logs
	$(MAKE) target-functional-tests
	$(MAKE) save-target-logs

$(METRICS_DIR)/coverage:
	mkdir -p $@

# Save the app log files for debugging of code coverage on target via Bamboo.
nb-code-coverage-target: $(TESTDRIVER) $(METRICS_DIR)/coverage
	$(MAKE) clean-target-logs
	swqa/bin/run_coverage target
	$(RSYNC) --links swqa/reports/coverage/target/ $(METRICS_DIR)/coverage
	$(MAKE) save-target-logs

# @todo: rsync to the official Metrics Web server, not a local document root.
nb-store-code-coverage-report:
	@mkdir -p $(HOME)/www
	$(RSYNC) metrics/www/ $(HOME)/www
	$(RSYNC) --links $(METRICS_DIR)/coverage $(HOME)/www
	$(MAKE) --silent -C $(HOME)/www

.PHONY: ci-smoke-vm-tests nb-functional-target-tests nb-store-code-coverage-report target-power-tests


# Deploy to target.

CONSOLE_ROOT_FS=/opt/rfs200-rootfs

CONSOLE_DEPLOY_DIR=$(CONSOLE_ROOT_FS)/opt/redstripe
CONSOLE_DEPLOY_BINDIR=$(CONSOLE_DEPLOY_DIR)/usr/local/bin
CONSOLE_DEPLOY_CLINICAL_LOG_DIR=$(CONSOLE_DEPLOY_DIR)/log/clinical

$(CONSOLE_ROOT_FS):
	$(MAKE) -C crossdevelop cross-rootfs

$(CONSOLE_DEPLOY_DIR): $(CONSOLE_ROOT_FS)
	sudo mkdir -p $@

deploy-target-libs: $(CONSOLE_DEPLOY_DIR)
	$(MAKE) -C libraries deploy

# Copies rootfs overlay directory tree, and deletes unwanted Liberation font files.
deploy-target-assets: $(CONSOLE_ROOT_FS)
	sudo $(RSYNC) rootfs-assets/ $(CONSOLE_ROOT_FS)/
	if [ -d rootfs-assets-dev ]; then sudo $(RSYNC) --copy-links rootfs-assets-dev/ $(CONSOLE_ROOT_FS)/; fi
	if [ -f $(CONSOLE_ROOT_FS)/root/.ssh/authorized_keys ]; then sudo chmod 600 $(CONSOLE_ROOT_FS)/root/.ssh/authorized_keys; fi
	sudo rm -rf /opt/rfs200-rootfs/usr/share/fonts/liberation

deploy-target-apps: target-apps deploy-target-libs deploy-target-assets $(CONSOLE_DEPLOY_DIR)
	sudo $(RSYNC) --relative $(TARGET_DIST_DIR) $(CONSOLE_DEPLOY_DIR)/
	sudo $(RSYNC) --relative $(TARGET_APP_ASSETS) $(CONSOLE_DEPLOY_DIR)/

deploy-target-tests: target-unit-tests deploy-target-libs $(CONSOLE_DEPLOY_DIR)
	sudo $(RSYNC) --relative $(TARGET_UNIT_TEST_BINS) $(CONSOLE_DEPLOY_DIR)/

clean-deploy-target-apps:
	sudo rm -rf $(CONSOLE_DEPLOY_DIR)

clean-vm-logs:
	rm -f $(VM_DIST_DIR)/*.log

$(TARGET_VARLOG_DIR):
	mkdir -p $@

save-target-logs: $(TARGET_VARLOG_DIR)
	-cp $(CONSOLE_DEPLOY_DIR)/$(TARGET_DIST_DIR)/*.log $(TARGET_DIST_DIR) 2>/dev/null
	-cp -R $(CONSOLE_DEPLOY_CLINICAL_LOG_DIR) $(TARGET_DIST_DIR)
	-cp $(CONSOLE_ROOT_FS)/var/log/messages* $(TARGET_VARLOG_DIR)/ 2>/dev/null

clean-target-logs:
	sudo rm -f $(CONSOLE_DEPLOY_DIR)/$(TARGET_DIST_DIR)/*.log
	sudo rm -f $(CONSOLE_DEPLOY_CLINICAL_LOG_DIR)/*.csv
	sudo rm -f $(CONSOLE_DEPLOY_CLINICAL_LOG_DIR)/debug/*
	sudo rm -f $(CONSOLE_ROOT_FS)/var/log/message*
	rm -f $(TARGET_DIST_DIR)/*.log
	rm -rf $(TARGET_DIST_DIR)/clinical
	rm -rf $(TARGET_VARLOG_DIR)

# This is used to update the kernel in the SD cards of the test fixture consoles.

update-sdcards: deploy-target-assets $(CONSOLE_DEPLOY_DIR)
	sudo cp crossdevelop/images/uImage $(CONSOLE_ROOT_FS)/root/
	sudo cp $(CONSOLE_DEPLOY_BINDIR)/update_sdcard $(CONSOLE_DEPLOY_BINDIR)/redstripe
	swqa/bin/cycle_all_consoles target 80
	sudo rm -f $(CONSOLE_ROOT_FS)/root/uImage

.PHONY: deploy-target-libs deploy-target-assets deploy-target-apps deploy-target-tests clean-deploy-target-apps clean-vm-logs save-target-logs clean-target-logs update-sdcards


# Create software update image

UPDATE_DIR=software_update
UPDATE_TARBALL=$(UPDATE_DIR)/rfs.tar.bz2
UPDATE_TARBALL_ENCRYPTED=$(UPDATE_TARBALL).pgp
UPDATE_MANIFEST=$(UPDATE_DIR)/manifest.json
UPDATE_MANIFEST_SIGNATURE=$(UPDATE_MANIFEST).sig
UPDATE_IMAGE=$(UPDATE_DIR)/image.bin

$(UPDATE_DIR):
	mkdir -p $@

$(UPDATE_TARBALL): $(UPDATE_DIR) deploy-target-apps clean-target-logs
	sudo tar --create --bzip2 --directory /opt --file $@ rfs200-rootfs

$(UPDATE_TARBALL_ENCRYPTED): $(UPDATE_TARBALL)
	bin/encrypt_update_tarball $^ $@

$(UPDATE_MANIFEST): $(UPDATE_TARBALL_ENCRYPTED)
	bin/generate_update_manifest $^ >$@

$(UPDATE_MANIFEST_SIGNATURE): $(UPDATE_MANIFEST)
	bin/sign_update_manifest $^ $@

$(UPDATE_IMAGE): $(UPDATE_MANIFEST) $(UPDATE_MANIFEST_SIGNATURE) $(UPDATE_TARBALL_ENCRYPTED)
	cat /dev/null >$@
	bin/tlv_cat "M" $(UPDATE_MANIFEST) >>$@
	bin/tlv_cat "S" $(UPDATE_MANIFEST_SIGNATURE) >>$@
	bin/tlv_cat "P" $(UPDATE_TARBALL_ENCRYPTED) >>$@

update-image: $(UPDATE_IMAGE)

clean-update-image:
	rm -rf $(UPDATE_DIR)

.PHONY: update-image clean-update-image


# Analyze the source code.

lint:  ## Run flexelint on all project apps
	bin/project_flexelint $(APPS)

.PHONY: lint


# Build the documentation.

docs:
	bin/run_doxygen

clean-docs:
	rm -rf docs $(DOXYGEN_ERRORS)

.PHONY: docs clean-docs


# Install the developer's toolbox

BIN=/usr/bin
LOCAL_BIN=/usr/local/bin

WGET=wget --continue --no-check-certificate
UNZIP=unzip -q

CPPCHECK=$(BIN)/cppcheck
CPPCHECK_VERSION=1.71
CPPCHECK_DIR=cppcheck-$(CPPCHECK_VERSION)
CPPCHECK_SOURCE=https://github.com/danmar/cppcheck/archive/$(CPPCHECK_VERSION).zip

DOXYGEN=$(LOCAL_BIN)/doxygen
DOXYGEN_VERSION=Release_1_8_11
DOXYGEN_DIR=doxygen-$(DOXYGEN_VERSION)
DOXYGEN_SOURCE=https://github.com/doxygen/doxygen/archive/$(DOXYGEN_VERSION).zip

GITFLOW=/usr/lib/git-core/git-flow

NTP=$(BIN)/ntpq

UNCRUSTIFY=$(LOCAL_BIN)/uncrustify
UNCRUSTIFY_VERSION=uncrustify-0.61
UNCRUSTIFY_DIR=uncrustify-$(UNCRUSTIFY_VERSION)
UNCRUSTIFY_SOURCE=https://github.com/bengardner/uncrustify/archive/$(UNCRUSTIFY_VERSION).zip

toolbox: $(CPPCHECK) $(DOXYGEN) $(GITFLOW) $(NTP) $(UNCRUSTIFY)

.PHONY: toolbox

$(CPPCHECK):
	$(WGET) $(CPPCHECK_SOURCE)
	@$(UNZIP) $(CPPCHECK_VERSION).zip && rm $(CPPCHECK_VERSION).zip
	$(MAKE) -C $(CPPCHECK_DIR) CFGDIR=.config/cppcheck
	sudo $(MAKE) -C $(CPPCHECK_DIR) install
	@rm -rf $(CPPCHECK_DIR)
	@cppcheck --version

$(DOXYGEN):
	$(WGET) $(DOXYGEN_SOURCE)
	@$(UNZIP) $(DOXYGEN_VERSION).zip && rm $(DOXYGEN_VERSION).zip
	sudo apt-get -y install bison cmake flex
	cd $(DOXYGEN_DIR) && cmake -G "Unix Makefiles" .
	$(MAKE) -C $(DOXYGEN_DIR)
	sudo $(MAKE) -C $(DOXYGEN_DIR) install
	@rm -rf $(DOXYGEN_DIR)
	@echo -n "$(@F) " && $(@F) --version

$(GITFLOW):
	sudo apt-get -y install $(@F)
	@echo -n "$(@F)" && $@ version

$(NTP):
	sudo apt-get -y install ntp
	@$(@F) --version

$(UNCRUSTIFY):
	$(WGET) $(UNCRUSTIFY_SOURCE)
	@$(UNZIP) $(UNCRUSTIFY_VERSION).zip && rm $(UNCRUSTIFY_VERSION).zip
	cd $(UNCRUSTIFY_DIR) && ./configure --quiet
	$(MAKE) -C $(UNCRUSTIFY_DIR)
	sudo $(MAKE) -C $(UNCRUSTIFY_DIR) install
	@rm -rf $(UNCRUSTIFY_DIR)
	@uncrustify --version

clean-toolbox:
	sudo rm -f $(CPPCHECK) $(DOXYGEN) $(UNCRUSTIFY)
	# Just making sure...
	sudo apt-get -y remove cppcheck doxygen uncrustify
	sudo rm -rf /usr/bin/cppcheck /usr/bin/doxygen /usr/bin/uncrustify
	# Let's never remove ntp.
	# sudo apt-get -y remove ntp
	sudo apt-get -y remove git-flow
	sudo apt-get -y autoremove

.PHONY: clean-toolbox


# Install the desired Qt version.

QT_PATH=/opt/Qt$(QT_REVISION)
QT_BIN_DIR=$(QT_PATH)/$(QT_VERSION)/gcc_64/bin

QT_SET_PATH=/etc/profile.d/qt_path.sh

QT_INSTALLER=qt-opensource-linux-x64-$(QT_REVISION).run
QT_INSTALLER_SOURCE=http://download.qt.io/archive/qt/$(QT_VERSION)/$(QT_REVISION)/$(QT_INSTALLER)

qt-install: $(QT_PATH) $(QT_SET_PATH)

$(QT_PATH):  ## Installs Qt from download.qt.io
	@echo "Installing Qt $(QT_REVISION)"
	# Some libraries required.
	sudo apt-get -y install libfontconfig1-dev libfreetype6-dev libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev libxcb1-dev libx11-xcb-dev libxcb-glx0-dev
	# Enables OpenGL.
	sudo apt-get -y install libgl1-mesa-dev
	# Downloads and launches interactive installer (GUI).
	$(WGET) $(QT_INSTALLER_SOURCE)
	chmod +x $(QT_INSTALLER)
	@echo "In the GUI dialog, please use the suggested path: $(QT_PATH)"
	sudo ./$(QT_INSTALLER)
	@rm -rf $(QT_INSTALLER)

$(QT_SET_PATH):  ## Adds Qt binaries to the PATH of all users.
	sudo bash -c "echo 'PATH="$(QT_BIN_DIR):\$$PATH"' >/etc/profile.d/qt_path.sh"

clean-qt:
	sudo apt-get -y remove qt5-default qttools5-dev-tools qtcreator qtdeclarative5-dev
	sudo apt-get -y autoremove
	sudo rm -rf $(QT_PATH)
	sudo rm -f /etc/profile.d/qt_path.sh

.PHONY: clean-qt
