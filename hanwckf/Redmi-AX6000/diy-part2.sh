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
# rm -rf feeds/packages/lang/golang
# git clone https://github.com/sbwml/packages_lang_golang -b 21.x feeds/packages/lang/golang

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
# add iperf3
# rm -rf feeds/packages/net/iperf
# rm -rf feeds/packages/net/iperf3
# rm -rf feeds/luci/applications/luci-app-iperf3

# replace a theme
# rm -rf ./feeds/luci/themes/luci-theme-argon
# git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon

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
