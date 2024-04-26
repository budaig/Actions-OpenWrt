#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# ## TIME y "更换内核"
#sed -i 's/KERNEL_PATCHVER:=5.4/KERNEL_PATCHVER:=4.19/g' ./target/linux/mediatek/Makefile
#sed -i 's/KERNEL_TESTING_PATCHVER:=5.4/KERNEL_TESTING_PATCHVER:=4.19/g' ./target/linux/mediatek/Makefile
#TIME y "更换内核结束"

# ## Modify default IP
# package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

#  ## Modify hostname
#sed -i 's/OpenWrt/budairt/g' package/base-files/files/bin/config_generate

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

del_data="
feeds/packages/net/v2ray-geodata
feeds/packages/net/v2ray-core
feeds/packages/net/v2ray-plugin
feeds/packages/net/xray-plugin
feeds/packages/net/xray-core
feeds/packages/lang/golang
"

for cmd in $del_data;
do
 rm -rf $cmd
 echo "Deleted $cmd"
done

# ## update golang 20.x to 22.x
git clone https://github.com/sbwml/packages_lang_golang -b 21.x feeds/packages/lang/golang

# ## -------------- alist ---------------------------
# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
git clone https://github.com/sbwml/luci-app-alist.git package/custom/alist

## customize alist ver
# sleep 1
# alver=3.32.0
# alwebver=3.32.0
# alsha256=($(curl -sL https://codeload.github.com/alist-org/alist/tar.gz/v$alver | shasum -a 256))
# alwebsha256=($(curl -sL https://github.com/alist-org/alist-web/releases/download/$alwebver/dist.tar.gz | shasum -a 256))
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$alver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$alsha256"'/g;26 s/  HASH:=.*/  HASH:='"$alwebsha256"'/g' package/custom/alist/Makefile

# change default port: version 3.33.0 and up
# sed -i 's/5244/5246/g' package/custom/alist/files/alist.config
# sed -i 's/5244/5246/g' package/custom/alist/files/alist.init
# change default port: version 3.32.0 and below
# sed -i 's/5244/5246/g' package/custom/alist/luci-app-alist/root/etc/config/alist
# sed -i 's/5244/5246/g' package/custom/alist/luci-app-alist/root/etc/init.d/alist
# ## ---------------------------------------------------------

# ## -------------- lucky ---------------------------
# rm -rf feeds/packages/net/lucky
rm -rf feeds/luci/applications/luci-app-lucky
git clone https://github.com/gdy666/luci-app-lucky.git package/custom/lucky
# git clone https://github.com/sirpdboy/luci-app-lucky.git package/custom/lucky
sleep 1
## customize lucky ver
# wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
lkver=2.6.2
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/custom/lucky/lucky/Makefile
# wget https://github.com/gdy666/lucky-files$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.5.1
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/lucky\/releases\/download\/v/lucky-files\/raw\/main\//g' package/custom/lucky/lucky/Makefile
# cat package/custom/lucky/lucky/Makefile
# ## ---------------------------------------------------------

# ## add chatgpt-web
# rm -rf feeds/packages/net/luci-app-chatgpt-web
# rm -rf feeds/luci/applications/luci-app-chatgpt-web
git clone https://github.com/sirpdboy/luci-app-chatgpt-web package/custom/chatgpt-web

# ## -------------- v2raya ---------------------------
rm -rf feeds/packages/net/v2raya
rm -rf feeds/luci/applications/luci-app-v2raya
git clone https://github.com/v2rayA/v2raya-openwrt package/custom/v2raya

## customize v2raya ver
# sleep 1
# v2aver=2.2.5.1
# v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
# v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;59 s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' package/custom/v2raya/v2raya/Makefile

rm -rf package/custom/v2raya/v2ray-core

## use yichya/luci-app-xray
# rm -rf package/custom/v2raya/xray-core
# git clone https://github.com/yichya/luci-app-xray package/custom/v2raya/xray-core
# mv package/custom/v2raya/xray-core

## use v2raya-openwrt/xray-core
# customize xraycore ver(删除PKG_HASH)
# sed -i 's/=1.8.8/=1.8.9/g;13d' package/custom/v2raya/xray-core/Makefile
# customize xraycore ver(修改PKG_HASH)
sleep 1
xrver=1.8.11
xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
sed -i '8 s/.*/PKG_VERSION:='"$xrver"'/g;13 s/.*/PKG_HASH:='"$xrsha256"'/g' package/custom/v2raya/xray-core/Makefile

## 更新v2ra geoip geosite 数据库

datetime1=$(date +"%Y%m%d%H%M")
ipsha256=($(curl -sL https://github.com/v2fly/geoip/releases/latest/download/geoip.dat | shasum -a 256))
sed -i '15 s/.*/GEOIP_VER:='"$datetime1"'/g;18 s/.*/  URL:=https:\/\/github.com\/v2fly\/geoip\/releases\/latest\/download\//g;21 s/.*/  HASH:='"$ipsha256"'/g' package/custom/v2raya/v2fly-geodata/Makefile
# # https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat

datetime2=$(date +"%Y%m%d%H%M%S")
sitesha256=($(curl -sL https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat | shasum -a 256))
sed -i '24 s/.*/GEOSITE_VER:='"$datetime2"'/g;27 s/.*/  URL:=https:\/\/github.com\/v2fly\/domain-list-community\/releases\/latest\/download\//g;30 s/.*/  HASH:='"$sitesha256"'/g' package/custom/v2raya/v2fly-geodata/Makefile
# https://github.com/Loyalsoldier/domain-list-custom/releases/latest/download/geosite.dat
# https://github.com/vrichv/better-geosite/releases/latest/download/geosite.dat
# 若要使用上面两个的 需要替换URL_FILE:=dlc.dat为geosite.dat

# ipver=202403280038
# ipsha256=($(curl -sL https://github.com/v2fly/geoip/releases/download/$ipver/geoip.dat | shasum -a 256))
# sed -i '15 s/.*/GEOIP_VER:='"$ipver"'/g;21 s/.*/  HASH:='"$ipsha256"'/g' package/custom/v2raya/v2fly-geodata/Makefile
# sitever=20240324094850
# # sitesha256=($(curl -sL https://github.com/v2fly/domain-list-community/releases/download/$sitever/dlc.dat | shasum -a 256))
# sed -i '24 s/.*/GEOSITE_VER:='"$sitever"'/g;30 s/.*/  HASH:='"$sitesha256"'/g' package/custom/v2raya/v2fly-geodata/Makefile

# ipver=latest
# ipsha256=($(curl -sL https://github.com/v2fly/geoip/releases/$ipver/download/geoip.dat | shasum -a 256))
# sed -i '15 s/.*/GEOIP_VER:='"$ipver"'/g;s/download\/$(GEOIP_VER)/$(GEOIP_VER)\/download/g;21 s/.*/  HASH:='"$ipsha256"'/g' package/custom/v2raya/v2fly-geodata/Makefile
# sitever=latest
# sitesha256=($(curl -sL https://github.com/v2fly/domain-list-community/releases/$sitever/download/dlc.dat | shasum -a 256))
# sed -i '24 s/.*/GEOSITE_VER:='"$sitever"'/g;s/download\/$(GEOSITE_VER)/$(GEOSITE_VER)\/download/g;30 s/.*/  HASH:='"$sitesha256"'/g' package/custom/v2raya/v2fly-geodata/Makefile

## GeoSite-GFWlist4v2ra数据库 
curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /tmp/geosite.dat
sleep 1
mkdir package/custom/v2raya/luci-app-v2raya/root/usr/share/xray
# rm package/custom/v2raya/luci-app-v2raya/root/usr/share/xray/LoyalsoldierSite.dat
mv /tmp/geosite.dat package/custom/v2raya/luci-app-v2raya/root/usr/share/xray/LoyalsoldierSite.dat >/dev/null 2>&1
# ## ---------------------------------------------------------

# ## -------------- smartdns ---------------------------
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns package/custom/smartdns
git clone https://github.com/pymumu/luci-app-smartdns -b master package/custom/luci-app-smartdns
SMARTDNS_VER=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].commit.committer.date | awk -F "T" '{print $1}' | sed 's/\"//g' | sed 's/\-/\./g'`)
SMAERTDNS_SHA=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].sha | sed 's/\"//g'`)
sed -i '/PKG_MIRROR_HASH:=/d' package/custom/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/custom/smartdns/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$SMAERTDNS_SHA"'/g' package/custom/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/custom/luci-app-smartdns/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/custom/luci-app-smartdns/Makefile
# add anti-ad data
curl -sL -m 30 --retry 2 https://anti-ad.net/anti-ad-for-smartdns.conf -o /tmp/reject.conf
sleep 1
mkdir package/custom/smartdns/root/etc/smartdns/domain-set
mv /tmp/reject.conf package/custom/smartdns/root/etc/smartdns/domain-set/reject.conf >/dev/null 2>&1
# ## ---------------------------------------------------------

# ## replace a theme
# rm -rf ./feeds/luci/themes/luci-theme-argon
# git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon
# replace theme bg
rm feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/bg1.jpg -o /tmp/bg1.jpg 
mv /tmp/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# ## Enable Cache
# echo -e 'CONFIG_DEVEL=y\nCONFIG_CCACHE=y' >> .config

# CONFIG_TARGET_DEVICE_mediatek_mt7986_DEVICE_xiaomi_redmi-router-ax6000=y
# grep '^CONFIG_TARGET_DEVICE.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/' > DEVICE_NAME
# cat DEVICE_NAME
# xiaomi_redmi-router-ax6000
# ROOTFS

# grep '^CONFIG_TARGET_DEVICE.*DEVICE.*=y' .config | sed -r 's/.*TARGET_.*_(.*)_DEVICE_.*=y/\1/' > TARGET_NAME
# cat TARGET_NAME
# mt7986
# CONFIG_TARGET_PER_DEVICE_ROOTFS=y

# sleep 5
