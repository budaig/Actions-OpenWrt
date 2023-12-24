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
## passwall v2raya
# sed -i '$a src-git kenzok8s https://github.com/kenzok8/small' feeds.conf.default
## alist smartdns ddns-go
# echo 'src-git shidahuilang https://github.com/shidahuilang/openwrt-package' >>feeds.conf.default
## alist aria2 smartdns ddns-go lucky iperf3 v2raya zerotier openclash
# sed -i '$a src-git openwrt_kiddin9 https://github.com/kiddin9/openwrt-packages' feeds.conf.default
# src/gz openwrt_kiddin9 https://dl.openwrt.ai/latest/packages/aarch64_cortex-a53/kiddin9
