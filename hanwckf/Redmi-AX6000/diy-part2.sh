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

#TIME y "更换内核"
#sed -i 's/KERNEL_PATCHVER:=5.4/KERNEL_PATCHVER:=4.19/g' ./target/linux/mediatek/Makefile
#sed -i 's/KERNEL_TESTING_PATCHVER:=5.4/KERNEL_TESTING_PATCHVER:=4.19/g' ./target/linux/mediatek/Makefile
#TIME y "更换内核结束"

# Modify default IP
# package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# update golang 20.x to 21.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 21.x feeds/packages/lang/golang

# replace ddns-go
# rm -rf feeds/packages/net/ddns-go
# rm -rf feeds/luci/applications/luci-app-ddns-go
# git clone https://github.com/sirpdboy/luci-app-ddns-go feeds/packages/net/ddns-go   #or package/ddns-go
# cp -fR feeds/packages/net/ddns-go/luci-app-ddns-go feeds/luci/applications/luci-app-ddns-go

# use lucky over ddns-go
# rm -rf feeds/packages/net/lucky
# rm -rf feeds/luci/applications/luci-app-lucky
git clone https://github.com/gdy666/luci-app-lucky.git package/lucky

# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
git clone https://github.com/sbwml/luci-app-alist.git package/alist
# cp -fR feeds/packages/net/alist/luci-app-alist feeds/luci/applications/luci-app-alist

# add chatgpt-web
# rm -rf feeds/packages/net/luci-app-chatgpt-web
# rm -rf feeds/luci/applications/luci-app-chatgpt-web
# git clone https://github.com/sirpdboy/luci-app-chatgpt-web package/chatgpt-web

# add netspeedtest
# rm -rf feeds/packages/net/netspeedtest
# rm -rf feeds/luci/applications/luci-app-netspeedtest
# git clone https://github.com/sirpdboy/netspeedtest.git package/netspeedtest

# replace a theme
# rm -rf ./feeds/luci/themes/luci-theme-argon
# git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon

# update openclash
# rm -rf feeds/luci/applications/luci-app-openclash
# git clone -b v0.45.157-beta --depth=1 https://github.com/vernesong/OpenClash package/OpenClash && mv -n package/OpenClash/luci-app-openclash feeds/luci/applications/luci-app-openclash; rm -rf package/OpenClash
# git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
# git branch --set-upstream-to=origin/master master
# git clone --depth 1 -b master https://github.com/vernesong/OpenClash package/openclash/op && mv -n package/openclash/op/luci-app-openclash package/openclash; rm -rf package/openclash/op

# ##-----------------Add OpenClash dev core------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
# tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mkdir -p feeds/luci/applications/luci-app-openclash/root/etc/openclash/core
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash >/dev/null 2>&1
# rm -rf /tmp/clash.tar.gz >/dev/null 2>&1

# ##------------- tun core --------------------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/premium/clash-linux-arm64-2023.08.17-13-gdcc8d87.gz -o /tmp/clash.gz
# gzip -d /tmp/clash.gz /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_tun >/dev/null 2>&1

# # ##------------- meta core ---------------------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
# tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_meta >/dev/null 2>&1
# rm -rf /tmp/clash.tar.gz >/dev/null 2>&1

# # ##-------------- GeoIP 数据库 -----------------------------
# curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /tmp/GeoIP.dat
# mv /tmp/GeoIP.dat feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoIP.dat >/dev/null 2>&1

# # ##-------------- GeoSite 数据库 ---------------------------
# curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /tmp/GeoSite.dat
# mv /tmp/GeoSite.dat feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoSite.dat >/dev/null 2>&1
# # ##---------------------------------------------------------

# update v2raya
rm -rf feeds/packages/net/v2raya
rm -rf feeds/luci/applications/luci-app-v2raya
git clone -b master --depth=1 https://github.com/kiddin9/openwrt-packages package/kiddin9 && mv -n package/kiddin9/luci-app-v2raya package/luci-app-v2raya && mv -n package/kiddin9/v2raya package/v2raya; rm -rf package/kiddin9


# Enable Cache
# echo -e 'CONFIG_DEVEL=y\nCONFIG_CCACHE=y' >> .config

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
