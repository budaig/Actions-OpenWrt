#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
# package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# update golang

# use lucky over ddns-go
# rm -rf feeds/packages/net/lucky
# rm -rf feeds/luci/applications/luci-app-lucky
git clone https://github.com/gdy666/luci-app-lucky.git package/lucky
# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
git clone https://github.com/sbwml/luci-app-alist.git package/alist

# sed -i 's/PKG_VERSION:=2.1.0/PKG_VERSION:=2.2.4.6/g' feeds/packages/net/v2raya/Makefile
# OR
rm -rf feeds/packages/net/v2raya
rm -rf feeds/luci/applications/luci-app-v2raya
# # git clone -b master --depth=1 https://github.com/kiddin9/openwrt-packages package/kiddin9 && mv -n package/kiddin9/aria2 package/aria2 && mv -n package/kiddin9/luci-app-aria2 package/luci-app-aria2 && mv -n package/kiddin9/v2raya package/v2raya && mv -n package/kiddin9/luci-app-v2raya package/luci-app-v2raya; rm -rf package/kiddin9
# # sed -i 's/PKG_VERSION:=2.2.4.3/PKG_VERSION:=2.2.4.6/g' package/v2raya/makefile
# # sed -i 's/DEPENDS:=$(GO_ARCH_DEPENDS) \
    # # +ca-bundle \
    # # +kmod-nft-tproxy \
    # # +xray-core/DEPENDS:=$(GO_ARCH_DEPENDS) +ca-bundle/g' package/v2raya/makefile
git clone https://github.com/v2rayA/v2raya-openwrt package/csv2raya
sed -i 's/PKG_VERSION:=2.2.4.1/PKG_VERSION:=2.2.4.6/g' package/csv2raya/v2raya/Makefile

# rm -rf feeds/luci/applications/luci-app-openclash
# svn export -r v0.45.157-beta https://github.com/vernesong/OpenClash package/csopenclash/op && mv -n package/csopenclash/op/luci-app-openclash package/csopenclash; rm -rf package/csopenclash/op

#replace a theme
# rm -rf ./feeds/luci/themes/luci-theme-argon
# git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon

##-----------------Add OpenClash dev core------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
# tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mkdir -p feeds/luci/applications/luci-app-openclash/root/etc/openclash/core
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash >/dev/null 2>&1
# rm -rf /tmp/clash.tar.gz >/dev/null 2>&1
##---------------------------------------------------------

cat > package/base-files/files/etc/banner << EOF
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   B U D A I
 -----------------------------------------------------
 %D %V, %C
 -----------------------------------------------------
EOF