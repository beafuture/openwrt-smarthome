#
# Copyright (C) 2016-2016 pppei.net
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=smarthome
PKG_VERSION:=0.8.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/xfguo/lua-daemon
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=master
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING LICENCE

PKG_MAINTAINER:=ring0 <ring0@pppei.net>

PKG_BUILD_PARALLEL:=0
PKG_BUILD_DEPENDS:=lua

include $(INCLUDE_DIR)/package.mk

define Package/smarthome
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Yeelight device controller
  URL:=http://github.com/beafuture/smarthome
  DEPENDS:= +luasocket +lua
endef

define Package/smarthome/description
  SmartHome is daemon to control Yeelight smart device
endef

define Package/smarthome/conffiles
/etc/config/smarthome
endef

define Build/Configure

endef
define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/src/ clean
	$(MAKE) -C $(PKG_BUILD_DIR)/src/ \
		LIBDIR="$(TARGET_LDFLAGS)" \
		CC="$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_CPPFLAGS) -std=gnu99" \
		LD="$(TARGET_CROSS)ld -shared"
endef

define Package/smarthome/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/smarthome.lua $(1)/usr/bin/smarthome.lua
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/smarthome.init $(1)/etc/init.d/smarthome
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/smarthome.config $(1)/etc/config/smarthome
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DATA) ./files/smarthome.lua.controller $(1)/usr/lib/lua/luci/controller/smarthome.lua
	$(INSTALL_DATA) ./files/smarthome.lua.cbi $(1)/usr/lib/lua/luci/model/cbi/smarthome.lua
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/src/daemon.so $(1)/usr/lib/lua/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/smarthome.default $(1)/etc/uci-defaults/smarthome
endef

$(eval $(call BuildPackage,smarthome))
