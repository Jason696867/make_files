# Medtronic MITG R&D
# 5920 Longbow Drive, Boulder, CO
# Copyright (c) 2016 Medtronic
# All Rights Reserved.
#
# @file  crossdevelop/Makefile
#
# Install the applications required for redstripe cross development.
#
# Install or update the cross development toolchain and rootfs.

cross-console: cross-connection cross-rootfs

cross-develop: cross-console cross-toolchain


clean-cross-console: clean-cross-connection clean-cross-rootfs

clean-cross-develop: clean-cross-console clean-cross-toolchain


# Cross connection to console

BIN=/usr/bin
LOCAL_BIN=/usr/local/bin

CONFIG_DIR=config

MINICOM=$(BIN)/minicom
MINICOM_SETUP=/etc/minicom/minirc.redstripe

NETWORK_INTERFACES=/etc/network/interfaces

NFS_KERNEL_SERVER=/etc/init.d/nfs-kernel-server
NFS_EXPORTS=/etc/exports

cross-connection: minicom nfs

clean-cross-connection:
	sudo apt-get -y purge minicom nfs-kernel-server
	sudo apt-get -y autoremove
	if [ -f /etc/network/interfaces.1 ]; then sudo mv /etc/network/interfaces.1 /etc/network/interfaces; fi


# Minicom

minicom: $(MINICOM_SETUP)

$(MINICOM):
	sudo apt-get -y install $(@F)

$(MINICOM_SETUP): $(MINICOM)
	sudo cp "$(CONFIG_DIR)/$(@F)" $@


# NFS and Networking

nfs: $(NFS_KERNEL_SERVER)

$(NETWORK_INTERFACES):
	sudo cp --backup=numbered "$(CONFIG_DIR)/$(@F)" $@

$(NFS_EXPORTS): $(NETWORK_INTERFACES)
	sudo cp "$(CONFIG_DIR)/$(@F)" $@

$(NFS_KERNEL_SERVER): | $(NFS_EXPORTS)
	sudo apt-get -y install $(@F)
	sudo $(NFS_KERNEL_SERVER) start


# Cross-mounted console root filesystem

CROSS_DEVELOP_DEST=/opt

CROSS_ROOTFS_DIR=$(CROSS_DEVELOP_DEST)/rfs200-rootfs

cross-rootfs: $(CROSS_ROOTFS_DIR) nfs

$(CROSS_ROOTFS_DIR):
	sudo mkdir -p $@
	sudo tar xjf images/$(@F).tar.bz2 -C $@

clean-cross-rootfs:
	sudo rm -rf $(CROSS_ROOTFS_DIR)

update-rootfs:
	$(MAKE) clean-cross-rootfs
	$(MAKE) cross-rootfs


# Toolchain

CROSS_TOOLCHAIN_DIR=$(CROSS_DEVELOP_DEST)/rfs200-arm-crosstool-chain

cross-toolchain: $(CROSS_TOOLCHAIN_DIR)

$(CROSS_TOOLCHAIN_DIR):
	sudo tar xjf images/$(@F).tar.bz2 -C $(@D)
	sudo chown -R $(USER):$(USER) $@

clean-cross-toolchain:
	sudo rm -rf $(CROSS_TOOLCHAIN_DIR)

update-toolchain:
	$(MAKE) clean-cross-toolchain
	$(MAKE) cross-toolchain

.PHONY: cross-connection clean-cross-connection cross-console clean-cross-console nfs minicom cross-develop cross-toolchain cross-rootfs clean-cross-develop clean-cross-rootfs clean-cross-toolchain update-rootfs update-toolchain
