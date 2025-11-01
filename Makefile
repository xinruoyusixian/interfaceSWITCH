include $(TOPDIR)/rules.mk

PKG_NAME:=network-switcher
PKG_VERSION:=1.2.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Your Name <your@email.com>
PKG_LICENSE:=GPL-2.0

include $(INCLUDE_DIR)/package.mk

define Package/network-switcher
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=智能网络接口切换器
  DEPENDS:=+lua +luci-lib-json +luci-lib-nixio
  PKGARCH:=all
endef

define Package/network-switcher/description
  智能网络接口切换器，提供WAN和WWAN接口之间的自动故障切换和手动切换功能。
  支持主接口优先策略、网络连通性检测、自动回滚等高级功能。
endef

define Package/network-switcher/conffiles
/etc/config/network_switcher
endef

define Build/Compile
endef

define Package/network-switcher/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/network_switcher $(1)/etc/config/
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/network_switcher $(1)/etc/init.d/
	
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/network_switcher.sh $(1)/usr/bin/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/network_switcher.lua $(1)/usr/lib/lua/luci/controller/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/network_switcher
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/network_switcher/network_switcher.lua $(1)/usr/lib/lua/luci/model/cbi/network_switcher/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/network_switcher
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/network_switcher/overview.htm $(1)/usr/lib/lua/luci/view/network_switcher/
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/network_switcher/logs.htm $(1)/usr/lib/lua/luci/view/network_switcher/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/i18n/network-switcher.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,network-switcher))
