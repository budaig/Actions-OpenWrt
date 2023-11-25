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
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# update golang
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 20.x feeds/packages/lang/golang
# # replace ddns-go
rm -rf feeds/packages/net/ddns-go
rm -rf feeds/luci/applications/luci-app-ddns-go
# git clone https://github.com/sirpdboy/luci-app-ddns-go feeds/packages/net/ddns-go
#or package/ddns-go
# cp -fR feeds/packages/net/ddns-go/luci-app-ddns-go feeds/luci/applications/luci-app-ddns-go
# use lucky over ddns-go
# rm -rf feeds/packages/net/lucky
# rm -rf feeds/luci/applications/luci-app-lucky
git clone https://github.com/gdy666/luci-app-lucky.git package/lucky
# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
git clone https://github.com/sbwml/luci-app-alist package/alist
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