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

# Modify kernel
# include/kernel-5.4
# LINUX_VERSION-5.4 = .255
# LINUX_KERNEL_HASH-5.4.255 = 34d5ed902f47d90f27b9d5d6b8db0d3fa660834111f9452e166d920968a4a061
# LINUX_VERSION-5.4 = .252
# LINUX_KERNEL_HASH-5.4.252 = 3a78587523940374a7319089b63357c7dc412b90f5879d512265e59173588267
# LINUX_VERSION-5.4 = .225
# LINUX_KERNEL_HASH-5.4.225 = 59f596f6714317955cf481590babcf015aff2bc1900bd8e8dc8f7af73bc560aa
sed -i 's/LINUX_VERSION-5.4 = .255/LINUX_VERSION-5.4 = .225/g' include/kernel-5.4
sed -i 's/LINUX_KERNEL_HASH-5.4.255 = 34d5ed902f47d90f27b9d5d6b8db0d3fa660834111f9452e166d920968a4a061/LINUX_KERNEL_HASH-5.4.225 = 59f596f6714317955cf481590babcf015aff2bc1900bd8e8dc8f7af73bc560aa/g' include/kernel-5.4

# Modify default IP
# package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# update golang
# rm -rf feeds/packages/lang/golang
# git clone https://github.com/sbwml/packages_lang_golang -b 21.x feeds/packages/lang/golang
# update 20.x to 21.x
# # replace ddns-go
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
git clone https://github.com/sbwml/luci-app-alist.git feeds/packages/net/alist
# cp -fR feeds/packages/net/alist/luci-app-alist feeds/luci/applications/luci-app-alist
# add netspeedtest
# rm -rf feeds/packages/net/netspeedtest
# rm -rf feeds/luci/applications/luci-app-netspeedtest
git clone https://github.com/sirpdboy/netspeedtest.git package/netspeedtest
# add iperf3
# rm -rf feeds/packages/net/iperf
# rm -rf feeds/packages/net/iperf3
# rm -rf feeds/luci/applications/luci-app-iperf3
# git init package/luciiperf
# cd package/luciiperf
# git remote add origin https://github.com/kiddin9/openwrt-packages.git
# git config core.sparsecheckout true
# echo "luci-app-iperf" >> .git/info/sparse-checkout
# echo "luci-app-iperf3-server" >> .git/info/sparse-checkout
# git pull origin master
# cd ..
# cd ..

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

# Enable Cache
echo -e 'CONFIG_DEVEL=y\nCONFIG_CCACHE=y' >> .config

#下载安装包
 # make[2] -C feeds/packages/net/alist/alist download
 # make[2] -C feeds/packages/net/alist/luci-app-alist download
 # make[2] -C feeds/packages/net/ddns-go/ddns-go download
 # make[2] -C feeds/packages/net/ddns-go/luci-app-ddns-go download
 #编译固件
 # make[3] -C feeds/packages/net/alist/alist compile
 # make[3] -C feeds/packages/net/ddns-go/ddns-go compile
 # make[3] -C feeds/packages/net/ddns-go/luci-app-ddns-go compile
 # make[3] -C feeds/packages/net/alist/luci-app-alist compile