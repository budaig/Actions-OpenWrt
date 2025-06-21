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
package/feeds/luci/luci-app-passwall
package/feeds/luci/luci-app-shadowsocks-libev
package/feeds/luci/luci-app-ssr-libev-server
package/feeds/luci/luci-app-ssr-plus
package/feeds/luci/luci-app-vssr
feeds/packages/net/v2ray-geodata
feeds/packages/net/v2ray-core
feeds/packages/net/v2ray-plugin
feeds/packages/net/xray-plugin
feeds/packages/net/xray-core
feeds/packages/net/shadowsocks-libev
feeds/packages/net/shadowsocks-rust
feeds/packages/net/shadowsocksr-libev
"

for cmd in $del_data;
do
 rm -rf $cmd
 echo "Deleted $cmd"
done

# ## update golang 20.x to 23.x
# nl feeds/packages/lang/golang/golang/Makefile   #21.02 org ver1.19
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang


# ## -------------- adguardhome ---------------------------
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
git clone https://github.com/xiaoxiao29/luci-app-adguardhome -b master package/diy/adguardhome
# sleep 1
# aghver=0.107.61
# aghsha256=($(curl -sL https://github.com/AdguardTeam/AdGuardHome/releases/download/v$aghver/AdGuardHome_linux_arm64.tar.gz | shasum -a 256))
# echo adguardhome $aghver sha256=$aghsha256
# sed -i '10 s/.*/PKG_VERSION:='"$aghver"'/g;17 s/.*/PKG_MIRROR_HASH:='"$aghsha256"'/g' package/diy/adguardhome/AdguardHome/Makefile
# ## ---------------------------------------------------------


# ## -------------- openlist ---------------------------
rm -rf feeds/packages/net/openlist
rm -rf feeds/luci/applications/luci-app-openlist
git clone https://github.com/sbwml/luci-app-openlist -b main package/diy/openlist
# or git clone https://github.com/sbwml/luci-app-openlist -b dev package/diy/openlist
# 终端命令（TTYD）执行命令：
# [ -f "/www/luci-static/resources/ui.js" ] && echo "Yes" || echo "No"
# 返回 Yes 表示支持，返回 No 表示不支持。

## use latest openlist commit to build
# sleep 1

OpenList_date=$(echo -n `curl -sL https://api.github.com/repos/OpenListTeam/OpenList/commits | jq .[0].commit.committer.date | awk -F "T" '{print $1}' | sed 's/\"//g' | sed 's/\-/\./g'`)
OpenList_SHA=$(echo -n `curl -sL https://api.github.com/repos/OpenListTeam/OpenList/commits | jq .[0].sha | sed 's/\"//g'`)
echo openlist $OpenList_date sha="$OpenList_SHA"

#--olfever tag: Pre-release
olfrontendver=4.0.0-dce2182
olfrontendsha256=($(curl -sL https://github.com/OpenListTeam/OpenList-Frontend/releases/download/rolling/openlist-frontend-dist-v$olfrontendver.tar.gz | shasum -a 256))
echo openlist-frontend $olfrontendver sha256="$olfrontendsha256"

sed -i 's/PKG_WEB_VERSION:=.*/PKG_WEB_VERSION:='"$olfrontendver"'/g;s/PKG_SOURCE_DATE:=.*/PKG_SOURCE_DATE:='"$OpenList_date"'/g;s/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$OpenList_SHA"'/g;s/PKG_MIRROR_HASH.*/PKG_MIRROR_HASH:=skip/g;s/  HASH:=.*/  HASH:='"$olfrontendsha256"'/g;s/download\/v$(PKG_WEB_VERSION)/download\/rolling/g' package/diy/openlist/openlist/Makefile

#--olfever tag: Release
# olfrontendver=4.0.0-rc.4
# olfrontendsha256=($(curl -sL https://github.com/OpenListTeam/OpenList-Frontend/releases/download/v$olfrontendver/openlist-frontend-dist-v$olfrontendver.tar.gz | shasum -a 256))
# echo openlist-frontend $olfrontendver sha256="$olfrontendsha256"

# sed -i 's/PKG_WEB_VERSION:=.*/PKG_WEB_VERSION:='"$olfrontendver"'/g;s/PKG_SOURCE_DATE:=.*/PKG_SOURCE_DATE:='"$OpenList_date"'/g;s/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$OpenList_SHA"'/g;s/PKG_MIRROR_HASH.*/PKG_MIRROR_HASH:=skip/g;s/  HASH:=.*/  HASH:='"$olfrontendsha256"'/g' package/diy/openlist/openlist/Makefile

## use release openlist

cat package/diy/openlist/openlist/Makefile
# ## ---------------------------------------------------------


# ## -------------- lucky ---------------------------
rm -rf feeds/packages/net/lucky
rm -rf feeds/luci/applications/luci-app-lucky

#-- #/etc/config/lucky.daji/lucky.conf
# git clone -b v2.17.8 --single-branch https://github.com/gdy666/luci-app-lucky.git package/diy/lucky
git clone -b main https://github.com/gdy666/luci-app-lucky.git package/diy/lucky
sleep 1

## fix 21.02 loading webpage error
# # sed -i 's/admin\/services\/lucky/admin\/services\/lucky\/setting/g' package/diy/lucky/luci-app-lucky/root/usr/share/luci/menu.d/luci-app-lucky.json 
cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/luci-app-lucky.json package/diy/lucky/luci-app-lucky/root/usr/share/luci/menu.d/luci-app-lucky.json
if [ $? -eq 0 ]; then
    echo "luci-app-lucky.json copied"
else
    echo "luci-app-lucky.json copy failed"
fi

# ## use custom binary ver 2.17.3
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/luckyMakefile package/diy/lucky/lucky/Makefile
# if [ $? -eq 0 ]; then
    # echo "luckyMakefile copied"
# else
    # echo "luckyMakefile copy failed"
# fi
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/lucky package/diy/lucky/lucky/files/lucky
# if [ $? -eq 0 ]; then
    # echo "lucky bin copied"
# else
    # echo "lucky bin copy failed"
# fi

#-- #/etc/lucky/lucky.conf   #@go1.22
# git clone https://github.com/sirpdboy/luci-app-lucky.git -b main package/diy/lucky
# sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.15.7
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g' package/diy/lucky/lucky/Makefile
# sed -i '/PKG_SOURCE_VERSION:=/d' package/diy/lucky/lucky/Makefile
##- change configdir to /etc/config/lucky.daji
### a:
# sed -i 's/\/etc\/lucky/\/etc\/config\/lucky.daji/g' package/diy/lucky/luci-app-lucky/root/etc/config/lucky
### or b:
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/etcconfiglucky package/diy/lucky/luci-app-lucky/root/etc/config/lucky
# if [ $? -eq 0 ]; then
#     echo "etcconfiglucky copied"
# else
#     echo "etcconfiglucky copy failed"
# fi

# cat package/diy/lucky/lucky/Makefile
# ## ---------------------------------------------------------


# ## add chatgpt-web
# rm -rf feeds/packages/net/chatgpt-web
# rm -rf feeds/luci/applications/luci-app-chatgpt-web
# git clone https://github.com/sirpdboy/luci-app-chatgpt-web -b main package/diy/chatgpt-web


# ## add OpenAppFilter oaf
rm -rf feeds/luci/applications/luci-app-appfilter
rm -rf feeds/packages/net/open-app-filter
git clone -b master https://github.com/destan19/OpenAppFilter.git package/diy/OpenAppFilter


# ## add parentcontrol
# git clone -b main https://github.com/sirpdboy/luci-app-parentcontrol package/diy/parentcontrol
git clone -b main https://github.com/budaig/luci-app-parentcontrol package/diy/parentcontrol
# git clone -b main https://github.com/dsadaskwq/luci-app-parentcontrol package/diy/parentcontrol   #(已删)


# ## add tailscale
# git clone b main https://github.com/asvow/luci-app-tailscale package/diy/luci-app-tailscale


# # ##  -------------- sing-box +  ---------------------------
# git clone https://github.com/zaiyin/openwrt-luci-singbox -b main package/diy/luci-singbox   # not work
# https://github.com/srk24/luci-app-sing-box
# https://github.com/Vancltkin/luci-app-singbox-ui   for OpenWrt 23.05.5

## mannual setup
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2singbox/sing-box package/diy/luci-singbox/luci-app-singbox/files/sing-box
# if [ $? -eq 0 ]; then
    # echo "sing-box copied"
# else
    # echo "sing-box copy failed"
# fi

# cp -f ${GITHUB_WORKSPACE}/_modFiles/2singbox/lucisingboxMakefile package/diy/luci-singbox/Makefile
# if [ $? -eq 0 ]; then
    # echo "lucisingboxMakefile copied"
# else
    # echo "lucisingboxMakefile copy failed"
# fi

# # sed -i '28i \	$(INSTALL_BIN) ./files/sing-box $(1)/usr/bin/sing-box' package/diy/luci-singbox/Makefile
## mannual setup
# ## ---------------------------------------------------------


# ##  -------------- Passwall ---------------------------
rm -rf feeds/luci/applications/luci-app-passwall
git clone https://github.com/xiaorouji/openwrt-passwall -b main package/diy/passwall

# ##  -------------- Passwall2 ---------------------------
rm -rf feeds/luci/applications/luci-app-passwall2
git clone https://github.com/xiaorouji/openwrt-passwall2 -b main package/diy/passwall2
# 使用 openwrt-xray 不需要 +xray-core +geoview +v2ray-geoip +v2ray-geosite
sed -i '/	+xray-core +geoview +v2ray-geoip +v2ray-geosite/d'  package/diy/passwall2/luci-app-passwall2/Makefile
# 使用 sing-box 需要 +geoview
# sed -i 's/	+xray-core +geoview +v2ray-geoip +v2ray-geosite/	+geoview/g' package/diy/passwall2/luci-app-passwall2/Makefile


# ##  -------------- xray +  ---------------------------
## geodata
git clone https://github.com/yichya/openwrt-xray-geodata-cut -b master package/diy/openwrt-geodata
   #与 mosdns geodata 相同
## core
git clone https://github.com/yichya/openwrt-xray -b master package/diy/openwrt-xray
# custom ver
# https://api.github.com/repos/XTLS/Xray-core/commits   https://codeload.github.com/XTLS/Xray-core/tar.gz/v25.3.3?/Xray-core-25.3.3.tar.gz
# xrver=25.3.6
# # # xrver=25.1.30
# xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
# echo xray $xrver sha256=$xrsha256
# sed -i '4 s/.*/PKG_VERSION:='"$xrver"'/g;12 s/.*/PKG_HASH:='"$xrsha256"'/g' package/diy/openwrt-xray/Makefile

##  -------------- luci app xray ---------------------------
rm -rf feeds/luci/applications/luci-app-xray || echo "Failed to delete /luci-app-xray"

git clone -b master https://github.com/rafmilecki/luci-app-xjay package/diy/luci-app-xjay

# git clone -b main https://github.com/quanljh/luci-app-simple-xray package/diy/luci-app-simplexray
# sed -i '3i PKG_NAME:=luci-app-simple-xray\nPKG_VERSION:=0.1\nPKG_RELEASE:=1' package/diy/luci-app-simplexray/luci-app-simple-xray/Makefile

## for OpenWrt 21.02.0 and later
# git clone -b luci2 https://github.com/bi7prk/luci-app-xray.git package/diy/luci-app-xray   #for 21.02 and up

# git clone https://github.com/honwen/luci-app-xray.git package/diy/luci-app-xray   #for openwrt 21.02 兼容SagerNet/v2ray-core

## or ttimasdf xray/service name xapp/ luci for 21.02 and up---------------
# git clone https://github.com/ttimasdf/luci-app-xray -b master package/diy/luci-app-xapp   #for 19.07
# git clone https://github.com/ttimasdf/luci-app-xray -b main package/diy/luci-app-xapp   #for 21.02 and up

# disable auto start
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/etcconfigxapp.conf package/diy/luci-app-xapp/root/etc/config/xapp
# if [ $? -eq 0 ]; then
    # echo "xapp.conf copied"
# else
    # echo "xapp.conf copy failed"
# fi
# ttimasdf xray xapp ---------------

# ## ---------------------------------------------------------


# ## -------------- v2raya ---------------------------
# nl feeds/packages/net/v2raya/Makefile   #21.02 org ver2.1.0
rm -rf feeds/packages/net/v2raya
rm -rf feeds/luci/applications/luci-app-v2raya

## method 1: replace whole dir
# mkdir -p package/diy/v2raya
# mv -f ${GITHUB_WORKSPACE}/_modFiles/v2raya-openwrt/* package/diy/v2raya/
# if [ $? -eq 0 ]; then
    # echo "v2raya dir copied"
# else
    # echo "v2raya dir copy failed"
# fi
# chmod +x package/diy/v2raya/v2raya/files/v2raya.init
# chmod +x package/diy/v2raya/
# ls package/diy/v2raya

## method 2: clone then replace key files
git clone https://github.com/v2rayA/v2raya-openwrt -b master package/diy/v2raya
# mv package/diy/v2raya/v2raya feeds/packages/net/v2raya
# mv package/diy/v2raya/luci-app-v2raya feeds/luci/applications/luci-app-v2raya

rm -rf package/diy/v2raya/v2ray-core
rm -rf package/diy/v2raya/v2fly-geodata
rm -rf package/diy/v2raya/xray-core

## customize ca ver
# caver=20241223
# casha256=($(curl -sL https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_$caver.tar.xz | shasum -a 256))
# echo ca-certificates v$caver sha256=$casha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$caver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$casha256"'/g' package/diy/v2raya/ca-certificates/Makefile
# nl feeds/packages/net/v2raya/Makefile

## customize v2raya ver
# sleep 1
# v2aver=2.2.6.7
# v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
# v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
# echo v2raya v$v2aver sha256=$v2asha256
# echo v2raya-web v$v2aver sha256=$v2awebsha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;59 s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' package/diy/v2raya/v2raya/Makefile   #feeds/packages/net/v2raya/Makefile

# fix mijia cloud wrong dns (use xraycore)-------
# rm feeds/packages/net/v2raya/files/v2raya.init || echo "feeds/packages/net/v2raya/files/v2raya.init"
# rm package/diy/v2raya/v2raya/files/v2raya.init || echo "package/diy/v2raya/v2raya/files/v2raya.init"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2v2raya/v2raya.init package/diy/v2raya/v2raya/files/v2raya.init
# if [ $? -eq 0 ]; then
    # echo "v2raya.init copied"
# else
    # echo "v2raya.init copy failed"
# fi
# chmod +x package/diy/v2raya/v2raya/files/v2raya.init
# or 
# # v2raya 2.2.6.6 包含 嗅探过滤 解决 mijia cloud
# sed -i 's/v2ray_bin"/v2ray_bin" "\/usr\/bin\/xray"/g;s/v2ray_confdir"/v2ray_confdir" "\/etc\/v2raya\/xray"/g' package/diy/v2raya/v2raya/files/v2raya.init
#250522 sed -i '53i \	append_env_arg "config" "V2RAY_CONF_GEOLOADER=memconservative"' package/diy/v2raya/v2raya/files/v2raya.init

# fix mijia cloud ------------------------
# ## ---------------------------------------------------------


# ## -------------- chinadns-ng   wolfssl_noasm 是没有硬件加速指令的版本---------------------------
rm -rf feeds/packages/net/chinadns-ng   #(241212  openwrt21.02 PKG_VERSION:=2023.10.28; openwrt23.05 PKG_VERSION:=2024.10.14; openwrt24.10 PKG_VERSION:=2024.10.14)
rm -rf feeds/luci/applications/luci-app-chinadns-ng

# git clone https://github.com/izilzty/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241216 PKG_VERSION:=2023.06.05)
git clone https://github.com/pexcn/openwrt-chinadns-ng -b master package/diy/chinadns-ng  #(241216 PKG_VERSION:=2023.10.28   未适配 2.0 的新功能   PKG_VERSION:=2024.10.14 https://github.com/zfl9/chinadns-ng/commit/39d4881f83fa139b52cff9d8e306c4313bf758ad)
# # # chng_ver=2024.11.17
# # # chng_SHA256=($(curl -sL https://github.com/zfl9/chinadns-ng/releases/download/$chng_ver/chinadns-ng+wolfssl_noasm@aarch64-linux-musl@generic+v8a@fast+lto | shasum -a 256))
# chng_ver=2025.03.27
# chng_SHA256=($(curl -sL https://github.com/zfl9/chinadns-ng/releases/download/$chng_ver/chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto | shasum -a 256))
# echo chinadns-ng v$chng_ver sha256=$chng_SHA256
# sed -i '4 s/.*/PKG_VERSION:='"$chng_ver"'/g;9 s/.*/PKG_SOURCE_VERSION:='"$chng_SHA256"'/g' package/diy/chinadns-ng/Makefile

# git clone https://github.com/xiechangan123/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(250327 PKG_VERSION:=2024.12.22   241216 PKG_VERSION:=2024.11.17   241119 PKG_VERSION:=2024.10.14)
# git clone https://github.com/muink/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241216 PKG_VERSION:=2024.10.14)

# op1 start: custom install chinadns-ng bin for chinadns-dn and xray bin for paswal
cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/ver2Makefile package/diy/chinadns-ng/Makefile
if [ $? -eq 0 ]; then
    echo "chinadns-ng.Makefile copied"
else
    echo "chinadns-ng.Makefile copy failed"
fi
# op1 end

# op2 start: custom install chinadns-ng bin for chinadns-dn and sing-box bin for paswal
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/ver2Makefilewsingbox package/diy/chinadns-ng/Makefile
# if [ $? -eq 0 ]; then
    # echo "chinadns-ng.Makefile copied"
# else
    # echo "chinadns-ng.Makefile copy failed"
# fi

# cp -f ${GITHUB_WORKSPACE}/_modFiles/2singbox/sing-box package/diy/chinadns-ng/files/sing-box
# if [ $? -eq 0 ]; then
    # echo "sing-box copied"
# else
    # echo "sing-box copy failed"
# fi
# op2 end

# cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/chinadns-ng.init package/diy/chinadns-ng/files/chinadns-ng.init
# if [ $? -eq 0 ]; then
    # echo "chinadns-ng.init copied"
# else
    # echo "chinadns-ng.init copy failed"
# fi
# chmod 644 package/diy/chinadns-ng/files/chinadns-ng.init

cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/etcchinadnsconf.conf package/diy/chinadns-ng/files/defconfig.conf
if [ $? -eq 0 ]; then
    echo "chinadns-ng config.conf copied"
else
    echo "chinadns-ng config.conf copy failed"
fi

# 250526 remove
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/etcchinadnsconfig.conf package/diy/chinadns-ng/files/cusconfig.conf
# if [ $? -eq 0 ]; then
    # echo "chinadns-ng cusconfig.conf copied"
# else
    # echo "chinadns-ng cusconfig.conf copy failed"
# fi

## rv chnroute list
rm package/diy/chinadns-ng/files/chnroute.txt
rm package/diy/chinadns-ng/files/chnroute6.txt
rm package/diy/chinadns-ng/files/chinalist.txt
rm package/diy/chinadns-ng/files/gfwlist.txt

urlchnroutelist="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chnroute/chnroute.txt"
curl -sL -m 30 --retry 2 "$urlchnroutelist" -o package/diy/chinadns-ng/files/chnroute.txt
urlchnroute6list="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chnroute/chnroute6.txt"
curl -sL -m 30 --retry 2 "$urlchnroute6list" -o package/diy/chinadns-ng/files/chnroute6.txt

# 250526 remove
# rm package/diy/chinadns-ng/files/chinadns-ng.config
# rm package/diy/chinadns-ng/files/chinadns-ng-daily.sh
# rm package/diy/chinadns-ng/files/chinadns-ng.init

# ls package/diy/chinadns-ng/files
# ## ---------------------------------------------------------


# ## -------------- smartdns ---------------------------
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns -b master package/diy/smartdns
git clone https://github.com/pymumu/luci-app-smartdns -b master package/diy/luci-app-smartdns
#git clone -b main https://github.com/pymumu/smartdns-webui package/diy/smartdns-webui

## do not compile smartdns-ui
# 1. clone mod makefile
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/openwrtsmartdns46.Makefile package/diy/smartdns/Makefile
# if [ $? -eq 0 ]; then
    # echo "openwrtsmartdns46.Makefile copied"
# else
    # echo "openwrtsmartdns46.Makefile copy failed"
# fi

# 2. mod Openwrt-smartdns makefile   -  prefer 2.
# # sed -i '/define Build\/Compile\/smartdns-ui/a\\t$(TAB)cargo install --force --locked bindgen-cli' feeds/packages/net/smartdns/Makefile
sed -i '31 s/.*/ifneq ($(CONFIG_PACKAGE_smartdns-ui),)/g' package/diy/smartdns/Makefile
sed -i '32 s/.*/PKG_BUILD_DEPENDS:=rust\/host/g' package/diy/smartdns/Makefile
sed -i '34i \endif' package/diy/smartdns/Makefile

## update to the newest
SMARTDNS_VER=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].commit.committer.date | awk -F "T" '{print $1}' | sed 's/\"//g' | sed 's/\-/\./g'`)
SMAERTDNS_SHA=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].sha | sed 's/\"//g'`)
echo smartdns v$SMARTDNS_VER sha=$SMAERTDNS_SHA

sed -i '/PKG_MIRROR_HASH:=/d' package/diy/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/smartdns/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$SMAERTDNS_SHA"'/g' package/diy/smartdns/Makefile
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/luci-app-smartdns/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/diy/luci-app-smartdns/Makefile

## add anti-ad data
mkdir -p package/diy/luci-app-smartdns/root/etc/smartdns || echo "Failed to create /luci-app-smartdns/root/etc/smartdns"
cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/dns_rules_update.sh package/diy/luci-app-smartdns/root/etc/smartdns/dns_rules_update.sh
if [ $? -eq 0 ]; then
    echo "dns_rules_update copied"
else
    echo "dns_rules_update copy failed"
fi
chmod +x package/diy/luci-app-smartdns/root/etc/smartdns/dns_rules_update.sh

cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/sitefcm.dns package/diy/luci-app-smartdns/root/etc/smartdns/sitefcm.conf
if [ $? -eq 0 ]; then
    echo "sitefcm copied"
else
    echo "sitefcm copy failed"
fi

cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/blockADcooka.mos package/diy/luci-app-smartdns/root/etc/smartdns/blockADcooka.txt
if [ $? -eq 0 ]; then
    echo "blockADcooka copied"
else
    echo "blockADcooka copy failed"
fi

sleep 1
## add hululu1068 / anti-ad 广告smartdns规则
# urlreject="https://anti-ad.net/anti-ad-for-smartdns.conf"
urlreject="https://raw.githubusercontent.com/hululu1068/AdGuard-Rule/adrules/smart-dns.conf"
curl -sL -m 30 --retry 2 "$urlreject" -o package/diy/luci-app-smartdns/root/etc/smartdns/sitereject.conf
## add github hosts
curl -sL -m 30 --retry 2 https://raw.hellogithub.com/hosts -o package/diy/luci-app-smartdns/root/etc/smartdns/hostsgithub.txt
## add githubhosts for smartdns
urlgthosts="https://raw.githubusercontent.com/hululu1068/AdGuard-Rule/adrules/rules/github-hosts.conf"
curl -sL -m 30 --retry 2 "$urlgthosts" -o package/diy/luci-app-smartdns/root/etc/smartdns/hostsgithub.conf
## add direct-domain-list
# https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt
# urlcnlist="https://raw.githubusercontent.com/ixmu/smartdns-conf/main/direct-domain-list.conf"
# curl -sL -m 30 --retry 2 "$urlcnlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/sitedirect
## add proxy-domain-list
# https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt
# urlncnlist="https://raw.githubusercontent.com/ixmu/smartdns-conf/main/proxy-domain-list.conf"
# curl -sL -m 30 --retry 2 "$urlncnlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/siteproxy
## add china-list
# https://raw.githubusercontent.com/pexcn/daily/gh-pages/chinalist/chinalist.txt
urlchnlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/china-list.txt"
curl -sL -m 30 --retry 2 "$urlchnlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/chnlist
## add gfw list
# https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt
urlgfwlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt"
curl -sL -m 30 --retry 2 "$urlgfwlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/gfwlist
## add 秋风广告规则-hosts
# urladhosts="https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/Filters/AWAvenue-Ads-Rule-hosts.txt"
# curl -sL -m 30 --retry 2 "$urladhosts"  -o package/diy/luci-app-smartdns/root/etc/AWAvenueadshosts.txt
  #去除带!符号的6行
#sed -i '/!/d' package/diy/luci-app-smartdns/root/etc/AWAvenueadshosts.txt
  # or 替换!为#
#sed -i 's/!/#/g' package/diy/luci-app-smartdns/root/etc/AWAvenueadshosts.txt
## add reject-list
# urlrejlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt"
# curl -sL -m 30 --retry 2 "$urlrejlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/sitereject
# ls -l package/diy/luci-app-smartdns/root/etc/smartdns

# ## 若不安装 v2raya 则借用 smartdns 配置文件夹安装 xrayconfig
# mkdir -p package/diy/luci-app-smartdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/xraycore.init package/diy/luci-app-smartdns/root/etc/init.d/xray
# if [ $? -eq 0 ]; then
    # echo "xrayint copied"
# else
    # echo "xrayint copy failed"
# fi
# 2305 需要0755权限
# chmod +x package/diy/luci-app-smartdns/luci-app-smartdns/root/etc/init.d/xray

# mkdir -p package/diy/luci-app-smartdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/xraycorecfg.cst package/diy/luci-app-smartdns/root/etc/xray/xraycfg.json
# if [ $? -eq 0 ]; then
    # echo "xraycfg copied"
# else
    # echo "xraycfg copy failed"
# fi

# ## ---------------------------------------------------------


# ## replace a theme
# rm -rf ./feeds/luci/themes/luci-theme-argon
# git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon
# replace theme bg
rm feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
cp ${GITHUB_WORKSPACE}/_modFiles/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
if [ $? -eq 0 ]; then
    echo "bg1 copied"
else
    echo "bg1 copy failed"
fi
# or
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/bg1.jpg -o /tmp/bg1.jpg 
# mv /tmp/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# ## Enable Cache
# echo -e 'CONFIG_DEVEL=y\nCONFIG_CCACHE=y' >> .config
