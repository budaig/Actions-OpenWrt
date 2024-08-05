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
# sed -i '$a src-git kenzosmall https://github.com/kenzok8/small' feeds.conf.default
## alist smartdns ddns-go
# echo 'src-git shidahuilang https://github.com/shidahuilang/openwrt-package' >>feeds.conf.default
## alist aria2 smartdns ddns-go lucky iperf3 v2raya zerotier openclash
# sed -i '$a src-git openwrt_kiddin9 https://github.com/kiddin9/openwrt-packages' feeds.conf.default
# src/gz openwrt_kiddin9 https://dl.openwrt.ai/latest/packages/aarch64_cortex-a53/kiddin9


# echo GITHUB_WORKSPACE ${GITHUB_WORKSPACE}
# echo GITHUB_WORKSPACE $GITHUB_WORKSPACE

# cd $GITHUB_WORKSPACE/openwrt && ./scripts/feeds install luci-compat luci-lua-runtime luci-base csstidy luasrcdiet libpam
# if [ $? -eq 0 ]; then
    # echo "installed"
# else
    # echo "not installed"
# fi


# cd $GITHUB_WORKSPACE/openwrt

# find ./ | grep Makefile | grep alist | xargs rm -f
# git clone https://github.com/sbwml/luci-app-alist.git -b master package/diy/alist
# if [ $? -eq 0 ]; then
    # echo "alist copied"
# else
    # echo "alist not copied"
# fi

# find ./ | grep Makefile | grep lucky | xargs rm -f
# git clone https://github.com/gdy666/luci-app-lucky.git -b main package/diy/lucky
# if [ $? -eq 0 ]; then
    # echo "lucky copied"
# else
    # echo "lucky not copied"
# fi


# ## -------------- alist ---------------------------
# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
# alist 3.36 requires go 1.22
git clone https://github.com/sbwml/luci-app-alist.git -b master package/diy/alist
mv package/diy/alist/alist feeds/packages/net/alist
mv package/diy/alist/luci-app-alist feeds/luci/applications/luci-app-alist

## customize alist ver
# sleep 1
alver=3.33.0
alwebver=3.33.0
alsha256=($(curl -sL https://codeload.github.com/alist-org/alist/tar.gz/v$alver | shasum -a 256))
alwebsha256=($(curl -sL https://github.com/alist-org/alist-web/releases/download/$alwebver/dist.tar.gz | shasum -a 256))
echo alist $alver sha256=$alsha256
echo alist-web $alver sha256=$alwebsha256
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$alver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$alsha256"'/g;26 s/  HASH:=.*/  HASH:='"$alwebsha256"'/g' feeds/packages/net/alist/Makefile

# ## -------------- lucky ---------------------------
rm -rf feeds/packages/net/lucky
rm -rf feeds/luci/applications/luci-app-lucky

# #/etc/config/lucky.daji/lucky.conf
git clone https://github.com/gdy666/luci-app-lucky.git -b main package/diy/lucky
mv package/diy/lucky/lucky feeds/packages/net/lucky
mv package/diy/lucky/luci-app-lucky feeds/luci/applications/luci-app-lucky

# sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.6.2
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/diy/lucky/lucky/Makefile

# wget https://github.com/gdy666/lucky-files$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
lkver=2.10.8
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/lucky\/releases\/download\/v/lucky-files\/raw\/main\//g' feeds/packages/net/lucky/Makefile