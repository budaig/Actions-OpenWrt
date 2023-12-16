#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
# echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
# echo 'src-git messense https://github.com/messense/aliyundrive-webdav' >>feeds.conf.default
## ddns-go
# echo 'src-git ddns-go https://github.com/sirpdboy/luci-app-ddns-go' >>feeds.conf.default
## alist
# echo 'src-git alist https://github.com/sbwml/luci-app-alist' >>feeds.conf.default
## alist smartdns lucky openclash
# echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >>feeds.conf.default
## alist smartdns ddns-go
# echo 'src-git shidahuilang https://github.com/shidahuilang/openwrt-package' >>feeds.conf.default
## alist aria2 smartdns ddns-go lucky iperf3 v2raya zerotier openclash
# sed -i '$a src-git openwrt_kiddin9 https://github.com/kiddin9/openwrt-packages' feeds.conf.default

# update openclash
git clone -b v0.45.157-beta --depth=1 https://github.com/vernesong/openclash.git OpenClash
rm -rf feeds/luci/applications/luci-app-openclash
mv OpenClash/luci-app-openclash feeds/luci/applications/luci-app-openclash
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

# ##------------- meta core ---------------------------------
curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
chmod +x /tmp/clash >/dev/null 2>&1
mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_meta >/dev/null 2>&1
rm -rf /tmp/clash.tar.gz >/dev/null 2>&1

# ##-------------- GeoIP 数据库 -----------------------------
curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /tmp/GeoIP.dat
mv /tmp/GeoIP.dat feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoIP.dat >/dev/null 2>&1

# ##-------------- GeoSite 数据库 ---------------------------
curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /tmp/GeoSite.dat
mv /tmp/GeoSite.dat feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoSite.dat >/dev/null 2>&1
# ##---------------------------------------------------------