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
git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang

# ## -------------- alist ---------------------------
# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
git clone https://github.com/sbwml/luci-app-alist.git package/custom/alist
sleep 1
## customize alist ver
alver=3.32.0
alwebver=3.32.0
alsha256=($(curl -sL https://codeload.github.com/alist-org/alist/tar.gz/v$alver | shasum -a 256))
alwebsha256=($(curl -sL https://github.com/alist-org/alist-web/releases/download/$alwebver/dist.tar.gz | shasum -a 256))
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$alver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$alsha256"'/g;26 s/  HASH:=.*/  HASH:='"$alwebsha256"'/g' package/custom/alist/Makefile

# sed -i 's/5244/5246/g' package/custom/alist/luci-app-alist/root/etc/config/alist
# sed -i 's/5244/5246/g' package/custom/alist/luci-app-alist/root/etc/init.d/alist
# ## ---------------------------------------------------------

# ## -------------- lucky ---------------------------
# use lucky over ddns-go
# rm -rf feeds/packages/net/lucky
rm -rf feeds/luci/applications/luci-app-lucky
git clone https://github.com/gdy666/luci-app-lucky.git package/custom/lucky
# git clone https://github.com/sirpdboy/luci-app-lucky.git package/custom/lucky

sleep 1
## customize lucky ver
lkver=2.5.1
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/lucky\/releases\/download\/v/lucky-files\/raw\/main\//g' package/custom/lucky/lucky/Makefile
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
sleep 1
## customize v2raya ver
# v2aver=2.2.5.1
# v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
# v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;59 s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' package/custom/v2raya/v2raya/Makefile

rm -rf package/custom/v2raya/v2ray-core

## -------------- GeoSite-GFWlist4v2ra数据库 ---------------------------
curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /tmp/geosite.dat
sleep 1
mkdir package/custom/v2raya/luci-app-v2raya/root/usr/share/xray
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
# ## ---------------------------------------------------------

# ## replace a theme
# rm -rf ./feeds/luci/themes/luci-theme-argon
# git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon
# replace theme bg
rm feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/bg1.jpg -o /tmp/bg1.jpg 
mv /tmp/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# ## -------------- oepnclash ---------------------------
# pushd feeds/luci/applications
# rm -rf luci-app-openclash
# git clone --depth 1 -b master https://github.com/vernesong/OpenClash openclash && mv -n openclash/luci-app-openclash luci-app-openclash; rm -rf openclash
# popd

##-----------------Add OpenClash dev core------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/dev/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
# tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mkdir -p feeds/luci/applications/luci-app-openclash/root/etc/openclash/core
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash >/dev/null 2>&1
# rm -rf /tmp/clash.tar.gz >/dev/null 2>&1

##------------- tun core --------------------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/premium/clash-linux-arm64-2023.08.17-13-gdcc8d87.gz -o /tmp/clash.gz
# gzip -d /tmp/clash.gz /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_tun >/dev/null 2>&1

##------------- meta core ---------------------------------
# curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-arm64.tar.gz -o /tmp/clash.tar.gz
# tar zxvf /tmp/clash.tar.gz -C /tmp >/dev/null 2>&1
# chmod +x /tmp/clash >/dev/null 2>&1
# mv /tmp/clash feeds/luci/applications/luci-app-openclash/root/etc/openclash/core/clash_meta >/dev/null 2>&1
# rm -rf /tmp/clash.tar.gz >/dev/null 2>&1

##-------------- GeoIP 数据库 -----------------------------
# curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /tmp/GeoIP.dat
# mv /tmp/GeoIP.dat feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoIP.dat >/dev/null 2>&1

##-------------- GeoSite 数据库 ---------------------------
# curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /tmp/GeoSite.dat
# mv /tmp/GeoSite.dat feeds/luci/applications/luci-app-openclash/root/etc/openclash/GeoSite.dat >/dev/null 2>&1
# ##---------------------------------------------------------

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
