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
package/feeds/luci/luci-app-passwall
package/feeds/luci/luci-app-ssr-plus
package/feeds/luci/luci-app-vssr
feeds/packages/net/v2ray-geodata
feeds/packages/net/v2ray-core
feeds/packages/net/v2ray-plugin
feeds/packages/net/xray-plugin
feeds/packages/net/xray-core
"

for cmd in $del_data;
do
 rm -rf $cmd
 echo "Deleted $cmd"
done

# ## update golang 20.x to 21.x
# nl feeds/packages/lang/golang/golang/Makefile   #21.02 org ver1.19
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 23.x feeds/packages/lang/golang
# use
# cp ${GITHUB_WORKSPACE}/_modFiles/2golang/golang-values.mk feeds/packages/lang/golang/golang-values.mk
# 21.x to use 21.4
# sed -i 's/GO_VERSION_PATCH:=12/GO_VERSION_PATCH:=4/g;s/PKG_HASH:=30e68af27bc1f1df231e3ab74f3d17d3b8d52a089c79bcaab573b4f1b807ed4f/PKG_HASH:=47b26a83d2b65a3c1c1bcace273b69bee49a7a7b5168a7604ded3d26a37bd787/g' feeds/packages/lang/golang/golang/Makefile

# ## -------------- adguardhome ---------------------------
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
git clone https://github.com/xiaoxiao29/luci-app-adguardhome -b master package/diy/adguardhome
# sleep 1
# aghver=0.107.52
# aghsha256=($(curl -sL https://github.com/AdguardTeam/AdGuardHome/releases/download/v$aghver/AdGuardHome_linux_arm64.tar.gz | shasum -a 256))
# echo adguardhome $aghver sha256=$aghsha256
# sed -i '10 s/.*/PKG_VERSION:='"$aghver"'/g;17 s/.*/PKG_MIRROR_HASH:='"$aghsha256"'/g' package/diy/adguardhome/AdguardHome/Makefile

# # mkdir -p package/diy/adguardhome/etc/config/adGuardConfig || echo "Failed to create /adguardhome/etc/config/adGuardConfig"
# # curl -sL -m 30 --retry 2 https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_arm64.tar.gz -o /tmp/AdGuardHome_linux_arm64.tar.gz && tar -xzf /tmp/AdGuardHome_linux_arm64.tar.gz -C /tmp && mv /tmp/AdGuardHome/AdGuardHome package/diy/adguardhome/etc/config/adGuardConfig/AdGuardHome

# ## ---------------------------------------------------------

# ## -------------- alist ---------------------------
# replace alist
# nl feeds/packages/net/alist/Makefile   #21.02 org ver3.19.0
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
# rm -rf luci-i18n-alist-zh-cn
# alist 3.36 requires go 1.22
## 无binary 需手动下载bin
# git clone https://github.com/lmq8267/luci-app-alist.git -b main package/diy/alist
## bin 和 luci
git clone https://github.com/sbwml/luci-app-alist.git -b main package/diy/alist
# git clone https://github.com/oppen321/luci-app-alist -b main package/diy/alist
# mv package/diy/alist/alist feeds/packages/net/alist
# mv package/diy/alist/luci-app-alist feeds/luci/applications/luci-app-alist

#-- use custom binary
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2alist/alistMakefile package/diy/alist/alist/Makefile
# if [ $? -eq 0 ]; then
    # echo "alistMakefile copied"
# else
    # echo "alistMakefile copy failed"
# fi
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2alist/alist338 package/diy/alist/alist/files/alist
# if [ $? -eq 0 ]; then
    # echo "alistbin copied"
# else
    # echo "alistbin copy failed"
# fi

## customize alist ver
# sleep 1
# alver=3.40.0
# alwebver=3.40.0
# alsha256=($(curl -sL https://codeload.github.com/alist-org/alist/tar.gz/v$alver | shasum -a 256))
# alwebsha256=($(curl -sL https://github.com/alist-org/alist-web/releases/download/$alwebver/dist.tar.gz | shasum -a 256))
# echo alist v$alver sha256=$alsha256
# echo alist-web v$alver sha256=$alwebsha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$alver"'/g;s/PKG_WEB_VERSION:=.*/PKG_WEB_VERSION:='"$alwebver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$alsha256"'/g;26 s/  HASH:=.*/  HASH:='"$alwebsha256"'/g' package/diy/alist/alist/Makefile

# change default port: version 3.33.0 and up
# sed -i 's/5244/5246/g' package/diy/alist/alist/files/alist.config
# sed -i 's/5244/5246/g' package/diy/alist/alist/files/alist.init
# change default port: version 3.32.0 and below
# sed -i 's/5244/5246/g' package/diy/alist/luci-app-alist/root/etc/config/alist
# sed -i 's/5244/5246/g' package/diy/alist/luci-app-alist/root/etc/init.d/alist
# ## ---------------------------------------------------------

# ## -------------- ikoolproxy ---------------------------
# git clone -b main https://github.com/ilxp/luci-app-ikoolproxy.git package/diy/luci-app-ikoolproxy
## add video rule
# sleep 1
# sed -i 's/-traditional -aes256/-aes256/g' package/diy/luci-app-ikoolproxy/root/usr/share/koolproxy/data/gen_ca.sh
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/kpupdate -o package/diy/luci-app-ikoolproxy/root/usr/share/koolproxy/kpupdate
# urlkp="https://cdn.jsdelivr.net/gh/ilxp/koolproxy@main/rules/koolproxy.txt"
# curl -sL -m 30 --retry 2 "$urlkp" -o package/diy/luci-app-ikoolproxy/root/usr/share/koolproxy/data/rules/koolproxy.txt >/dev/null 2>&1
# urldl="https://cdn.jsdelivr.net/gh/ilxp/koolproxy@main/rules/daily.txt"
# curl -sL -m 30 --retry 2 "$urldl" -o package/diy/luci-app-ikoolproxy/root/usr/share/koolproxy/data/rules/daily.txt >/dev/null 2>&1
# curl -sL -m 30 --retry 2 "$urlkpdat" -o /tmp/kp.dat
# mv /tmp/kp.dat package/diy/luci-app-ikoolproxy/root/usr/share/koolproxy/data/rules/kp.dat >/dev/null 2>&1
# ## ---------------------------------------------------------

# ## -------------- lucky ---------------------------
rm -rf feeds/packages/net/lucky
rm -rf feeds/luci/applications/luci-app-lucky

# #/etc/config/lucky.daji/lucky.conf
git clone https://github.com/gdy666/luci-app-lucky.git -b main package/diy/lucky
sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.6.2
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/diy/lucky/lucky/Makefile

# wget https://github.com/gdy666/lucky-files$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.10.8
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/lucky\/releases\/download\/v/lucky-files\/raw\/main\//g' package/diy/lucky/lucky/Makefile

#-- use custom binary ver 2.13.8
cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/luckyMakefile package/diy/lucky/lucky/Makefile
if [ $? -eq 0 ]; then
    echo "luckyMakefile copied"
else
    echo "luckyMakefile copy failed"
fi
cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/lucky package/diy/lucky/lucky/files/lucky
if [ $? -eq 0 ]; then
    echo "lucky bin copied"
else
    echo "lucky bin copy failed"
fi

# #/etc/lucky/lucky.conf   #@go1.22
# git clone https://github.com/sirpdboy/luci-app-lucky.git -b main package/diy/lucky
# sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.6.2
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/diy/lucky/lucky/Makefile
# sed -i '/PKG_SOURCE_VERSION:=/d' package/diy/lucky/lucky/Makefile
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2lucky/etcconfiglucky package/diy/lucky/luci-app-lucky/root/etc/config/lucky
# if [ $? -eq 0 ]; then
#     echo "etcconfiglucky copied"
# else
#     echo "etcconfiglucky copy failed"
# fi

# cat package/diy/lucky/lucky/Makefile
# ## ---------------------------------------------------------

# ## add chatgpt-web
# rm -rf feeds/packages/net/luci-app-chatgpt-web
# rm -rf feeds/luci/applications/luci-app-chatgpt-web
git clone https://github.com/sirpdboy/luci-app-chatgpt-web -b main package/diy/chatgpt-web

# ## add accesscontrolplus
# git clone -b main https://github.com/CrazyPegasus/luci-app-accesscontrol-plus package/diy/accesscontrolplus

# ## add OpenAppFilter oaf
git clone -b master https://github.com/destan19/OpenAppFilter.git package/diy/OpenAppFilter

# ## add eqosplus   需要安装eqosplus主题
# git clone -b main https://github.com/sirpdboy/luci-app-eqosplus package/diy/eqosplus 

# ## add parentcontrol
# git clone -b main https://github.com/sirpdboy/luci-app-parentcontrol package/diy/parentcontrol
git clone -b main https://github.com/budaig/luci-app-parentcontrol package/diy/parentcontrol
# git clone -b main https://github.com/dsadaskwq/luci-app-parentcontrol package/diy/parentcontrol   #(已删)

# ## -------------- qosmate ------------------------------
git clone -b main https://github.com/hudra0/qosmate.git package/diy/qosmate 
git clone -b main https://github.com/hudra0/luci-app-qosmate package/diy/luci-app-qosmate
sed -i '2 s/.*/    option enabled '0'/g' package/diy/qosmate/etc/config/qosmate
qmver=0.5.35
sed -i '4 s/.*/PKG_VERSION:='$qmver'/g' package/diy/qosmate/Makefile
sed -i '3 s/.*/VERSION='\"$qmver\"'/g' package/diy/qosmate/etc/qosmate.sh
echo qosmate v$qmver

# # https://github.com/LemonCrab666/luci-app-qosmate/blob/main/po/zh_Hans/qosmate.po
mkdir -p package/diy/luci-app-qosmate/po/zh_Hans || echo "Failed to create zh-Hans po"
cp -f ${GITHUB_WORKSPACE}/_modFiles/2qosmate/qosmate.po package/diy/luci-app-qosmate/po/zh_Hans/qosmate.po
if [ $? -eq 0 ]; then
    echo "qosmate.po copied"
else
    echo "qosmate.po copy failed"
fi
# ## ---------------------------------------------------------

# ##  -------------- xray +  ---------------------------
## geodata
git clone https://github.com/yichya/openwrt-xray-geodata-cut -b master package/diy/openwrt-geodata
   #与 mosdns geodata 相同
## core
git clone https://github.com/yichya/openwrt-xray -b master package/diy/openwrt-xray
# custom ver
# xrver=1.8.24
# xrver=24.11.21
# xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
# echo xray $xrver sha256=$xrsha256
# sed -i '4 s/.*/PKG_VERSION:='"$xrver"'/g;12 s/.*/PKG_HASH:='"$xrsha256"'/g' package/diy/openwrt-xray/Makefile

##  -------------- luci app xray ---------------------------
rm -rf feeds/luci/applications/luci-app-xray || echo "Failed to delete /luci-app-xray"

## yicha xray xstatus luci for 22.03 and up---------------
# git clone https://github.com/yichya/luci-app-xray -b master package/diy/luci-app-xstatus
# git clone https://github.com/xiechangan123/luci-i18n-xray-zh-cn -b main package/diy/luci-i18n-xray-zh-cn
# disable auto start
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/etcconfigxstatus.conf package/diy/luci-app-xstatus/core/root/etc/config/xray_core
# if [ $? -eq 0 ]; then
    # echo "xstatus.conf copied"
# else
    # echo "xstatus.conf copy failed"
# fi
# yicha xray xstatus ---------------

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

## customize immortalwrt orig v2raya
# nl feeds/packages/net/v2raya/Makefile
# v2aver=2.2.6.2
# v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
# v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
# echo v2raya v$v2aver sha256=$v2asha256
# echo v2raya-web v$v2aver sha256=$v2awebsha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' feeds/packages/net/v2raya/Makefile
# nl feeds/packages/net/v2raya/Makefile

## customize ca ver
# caver=20240203
# casha256=($(curl -sL https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_$caver.tar.xz | shasum -a 256))
# echo ca-certificates v$caver sha256=$casha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$caver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$casha256"'/g' package/diy/v2raya/ca-certificates/Makefile
# nl feeds/packages/net/v2raya/Makefile

## customize v2raya ver
sleep 1
v2aver=2.2.6.3
v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
echo v2raya v$v2aver sha256=$v2asha256
echo v2raya-web v$v2aver sha256=$v2awebsha256
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;59 s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' package/diy/v2raya/v2raya/Makefile   #feeds/packages/net/v2raya/Makefile

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
sed -i 's/v2ray_bin"/v2ray_bin" "\/usr\/bin\/xray"/g;s/v2ray_confdir"/v2ray_confdir" "\/etc\/v2raya\/xray"/g' package/diy/v2raya/v2raya/files/v2raya.init
sed -i '53i \	append_env_arg "config" "V2RAY_CONF_GEOLOADER=memconservative"' package/diy/v2raya/v2raya/files/v2raya.init

# # go 1.21.4
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2v2raya/100-go-mod-ver.patch package/diy/v2raya/xray-core/patches/100-go-mod-ver.patch
# if [ $? -eq 0 ]; then
    # echo "100-go-mod-ver copied"
# else
    # echo "100-go-mod-ver copy failed"
# fi
# sed -i 's/1.21.7/1.21.9/g' package/diy/v2raya/xray-core/patches/100-go-mod-ver.patch

# fix mijia cloud ------------------------

# use custom ver ----------------
# sleep 1
# vrver=5.22.0
# vrsha256=($(curl -sL https://codeload.github.com/v2fly/v2ray-core/tar.gz/v$vrver | shasum -a 256))
# echo v2ray v$vrver sha256=$vrsha256
# sed -i '8 s/.*/PKG_VERSION:='"$vrver"'/g;13 s/.*/PKG_HASH:='"$vrsha256"'/g' package/diy/v2raya/v2ray-core/Makefile

# xrver=24.11.21
# xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
# echo xray v$xrver sha256=$xrsha256
# sed -i '8 s/.*/PKG_VERSION:='"$xrver"'/g;13 s/.*/PKG_HASH:='"$xrsha256"'/g' package/diy/v2raya/xray-core/Makefile

## 更新v2ra geoip geosite 数据库

# datetime1=$(date +"%Y%m%d%H%M")
# ipsha256=($(curl -sL https://github.com/v2fly/geoip/releases/latest/download/geoip.dat | shasum -a 256))
# sed -i '15 s/.*/GEOIP_VER:='"$datetime1"'/g;18 s/.*/  URL:=https:\/\/github.com\/v2fly\/geoip\/releases\/latest\/download\//g;21 s/.*/  HASH:='"$ipsha256"'/g' package/diy/v2raya/v2fly-geodata/Makefile
# # # https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat

# datetime2=$(date +"%Y%m%d%H%M%S")
# sitesha256=($(curl -sL https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat | shasum -a 256))
# sed -i '24 s/.*/GEOSITE_VER:='"$datetime2"'/g;27 s/.*/  URL:=https:\/\/github.com\/v2fly\/domain-list-community\/releases\/latest\/download\//g;30 s/.*/  HASH:='"$sitesha256"'/g' package/diy/v2raya/v2fly-geodata/Makefile

# ## GeoSite-GFWlist4v2ra数据库 
# curl -sL -m 30 --retry 2 https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /tmp/geosite.dat
# sleep 1
# mkdir -p package/diy/v2raya/luci-app-v2raya/root/usr/share/xray || echo "Failed to create /luci-app-v2raya/root/usr/share/xray"
# # rm package/diy/v2raya/luci-app-v2raya/root/usr/share/xray/LoyalsoldierSite.dat
# mv /tmp/geosite.dat package/diy/v2raya/luci-app-v2raya/root/usr/share/xray/LoyalsoldierSite.dat >/dev/null 2>&1
# # mkdir -p package/diy/v2raya/luci-app-v2raya/root/usr/share/v2ray || echo "Failed to create /luci-app-v2raya/root/usr/share/v2ray"
# # # rm package/diy/v2raya/luci-app-v2raya/root/usr/share/xray/LoyalsoldierSite.dat
# # mv /tmp/geosite.dat package/diy/v2raya/luci-app-v2raya/root/usr/share/v2ray/LoyalsoldierSite.dat >/dev/null 2>&1
# ## ---------------------------------------------------------

# ## -------------- chinadns-ng   wolfssl_noasm 是没有硬件加速指令的版本---------------------------
rm -rf feeds/packages/net/chinadns-ng   #(241119 PKG_VERSION:=2023.10.28)
rm -rf feeds/luci/applications/luci-app-chinadns-ng

# git clone https://github.com/izilzty/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241126 PKG_VERSION:=2023.06.05)
git clone https://github.com/pexcn/openwrt-chinadns-ng -b master package/diy/chinadns-ng  #(241119 PKG_VERSION:=2023.10.28   未适配 2.0 的新功能   PKG_VERSION:=2024.10.14 https://github.com/zfl9/chinadns-ng/commit/39d4881f83fa139b52cff9d8e306c4313bf758ad)
# chng_ver=2024.11.17
# chng_SHA256=($(curl -sL https://github.com/zfl9/chinadns-ng/releases/download/$chng_ver/chinadns-ng+wolfssl_noasm@aarch64-linux-musl@generic+v8a@fast+lto | shasum -a 256))
# chng_SHA256=($(curl -sL https://github.com/zfl9/chinadns-ng/releases/download/$chng_ver/chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto | shasum -a 256))
# echo chinadns-ng v$chng_ver sha256=$chng_SHA256
# sed -i '4 s/.*/PKG_VERSION:='"$chng_ver"'/g;9 s/.*/PKG_SOURCE_VERSION:='"$chng_SHA256"'/g' package/diy/chinadns-ng/Makefile


# git clone https://github.com/xiechangan123/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241126 PKG_VERSION:=2024.11.17   241119 PKG_VERSION:=2024.10.14)
# git clone https://github.com/muink/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241126 PKG_VERSION:=2024.10.14)


cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/ver2Makefile package/diy/chinadns-ng/Makefile
if [ $? -eq 0 ]; then
    echo "chinadns-ng.Makefile copied"
else
    echo "chinadns-ng.Makefile copy failed"
fi

cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/chinadns-ng.init package/diy/chinadns-ng/files/chinadns-ng.init
if [ $? -eq 0 ]; then
    echo "chinadns-ng.init copied"
else
    echo "chinadns-ng.init copy failed"
fi

cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/etcchinadnsconf.conf package/diy/chinadns-ng/files/defconfig.conf
if [ $? -eq 0 ]; then
    echo "chinadns-ng config.conf copied"
else
    echo "chinadns-ng config.conf copy failed"
fi

cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/etcchinadnsconfig.conf package/diy/chinadns-ng/files/cusconfig.conf
if [ $? -eq 0 ]; then
    echo "chinadns-ng cusconfig.conf copied"
else
    echo "chinadns-ng cusconfig.conf copy failed"
fi

## rv chnroute list
rm package/diy/chinadns-ng/files/chnroute.txt
rm package/diy/chinadns-ng/files/chnroute6.txt
rm package/diy/chinadns-ng/files/chinalist.txt
rm package/diy/chinadns-ng/files/gfwlist.txt

urlchnroutelist="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chnroute/chnroute.txt"
curl -sL -m 30 --retry 2 "$urlchnroutelist" -o package/diy/chinadns-ng/files/chnroute.txt
urlchnroute6list="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chnroute/chnroute6.txt"
curl -sL -m 30 --retry 2 "$urlchnroute6list" -o package/diy/chinadns-ng/files/chnroute6.txt

ls package/diy/chinadns-ng/files
# ## ---------------------------------------------------------

# ## -------------- mosdns ---------------------------
# ls feeds/packages/net/mosdns
# nl feeds/packages/net/mosdns/Makefile   #ver5.1.3
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns

## gitclone sbwml/luci-app-mosdns
# 1. gitclone + mod makfile   -  prefer 1.

# git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/diy/mosdns
# sed -i '9 s/.*/LUCI_DEPENDS:=+mosdns +jsonfilter +curl +v2dat/g' package/diy/mosdns/luci-app-mosdns/Makefile
# sed -i 's/share\/v2ray/share\/xray/g' package/diy/mosdns/luci-app-mosdns/root/usr/share/mosdns/mosdns.sh

# 2. clone mod dir

# customize to use 5.3.x (TODO:531 include both https://github.com/sbwml/v2ray-geodata and https://github.com/yichya/openwrt-xray-geodata-cut Makefile)
# mkdir -p package/diy/mosdns
# cp -rf ${GITHUB_WORKSPACE}/_modFiles/mosdns533/* package/diy/mosdns/
# mv -f ${GITHUB_WORKSPACE}/_modFiles/mosdns533/* package/diy/mosdns/
# if [ $? -eq 0 ]; then
    # echo "mosdns dir copied"
# else
    # echo "mosdns dir copy failed"
# fi
# chmod +x package/diy/mosdns/luci-app-mosdns/root/usr/share/mosdns/mosdns.sh
# chmod +x package/diy/mosdns/luci-app-mosdns/root/etc/init.d/mosdns
# ls package/diy/mosdns

# git clone https://github.com/sbwml/v2ray-geodata -b master package/diy/v2ray-geodata
   #与 openwrt-xray geodat 相同
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2mosdns/mosdnsgeodataMakefile package/diy/v2ray-geodata/Makefile
# if [ $? -eq 0 ]; then
    # echo "mosdnsgeodataMakefile copied"
# else
    # echo "mosdnsgeodataMakefile copy failed"
# fi

## gitclone QiuSimons/openwrt-mos
# 1. gitclone + mod makfile

# git clone https://github.com/QiuSimons/openwrt-mos -b master package/diy/mosdns
# rm -rf package/diy/mosdns/v2ray-geodata
# sed -i 's/share\/v2ray/share\/xray/g' package/diy/mosdns/dat/def_config.yaml
# sed -i 's/share\/v2ray/share\/xray/g' package/diy/mosdns/dat/def_config_new.yaml
# sed -i 's/share\/v2ray/share\/xray/g' package/diy/mosdns/dat/def_config_v4.yaml
# sed -i 's/START=99/START=78/g' package/diy/mosdns/luci-app-mosdns/root/etc/init.d/mosdns
# sed -i 's/share\/v2ray/share\/xray/g' package/diy/mosdns/dat/def_config_v5.yaml

# 2. clone mod dir   -  prefer 2.
# customize to use https://github.com/yichya/openwrt-xray-geodata-cut Makefile)

# mkdir -p package/diy/mosdns

# mv -f ${GITHUB_WORKSPACE}/_modFiles/openwrt-mos-241005/* package/diy/mosdns/
# if [ $? -eq 0 ]; then
    # echo "mosdns dir copied"
# else
    # echo "mosdns dir copy failed"
# fi
# chmod +x package/diy/mosdns/luci-app-mosdns/root/etc/init.d/mosdns
# chmod +x package/diy/mosdns/

# ## ---------------------------------------------------------

# ## -------------- smartdns ---------------------------
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns -b master package/diy/smartdns
git clone https://github.com/pymumu/luci-app-smartdns -b master package/diy/luci-app-smartdns

## update to the newest
SMARTDNS_VER=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].commit.committer.date | awk -F "T" '{print $1}' | sed 's/\"//g' | sed 's/\-/\./g'`)
SMAERTDNS_SHA=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].sha | sed 's/\"//g'`)
echo smartdns v$SMARTDNS_VER sha=$SMAERTDNS_SHA

sed -i '/PKG_MIRROR_HASH:=/d' package/diy/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/smartdns/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$SMAERTDNS_SHA"'/g' package/diy/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/luci-app-smartdns/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/diy/luci-app-smartdns/Makefile

## add anti-ad data
mkdir -p package/diy/luci-app-smartdns/root/etc/smartdns/domain-set || echo "Failed to create /luci-app-smartdns/root/etc/smartdns/domain-set"
cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/dns_rules_update.sh package/diy/luci-app-smartdns/root/etc/smartdns/dns_rules_update.sh
if [ $? -eq 0 ]; then
    echo "dns_rules_update copied"
else
    echo "dns_rules_update copy failed"
fi
chmod +x package/diy/luci-app-smartdns/root/etc/smartdns/dns_rules_update.sh

cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/blockADcooka.mos package/diy/luci-app-smartdns/root/etc/smartdns/blockADcooka.txt
if [ $? -eq 0 ]; then
    echo "blockADcooka copied"
else
    echo "blockADcooka copy failed"
fi

sleep 1
## add hululu1068 / anti-ad 广告smartdns规则
# urlreject="https://anti-ad.net/anti-ad-for-smartdns.conf"
# urlreject="https://raw.githubusercontent.com/hululu1068/AdRules/main/smart-dns.conf"
# curl -sL -m 30 --retry 2 "$urlreject" -o /tmp/reject.conf
# mv /tmp/reject.conf package/diy/luci-app-smartdns/root/etc/smartdns/reject.conf >/dev/null 2>&1
## add github hosts
curl -sL -m 30 --retry 2 https://raw.hellogithub.com/hosts -o package/diy/luci-app-smartdns/root/etc/smartdns/hostsgithub.txt
## add githubhosts for smartdns
urlgthosts="https://raw.githubusercontent.com/hululu1068/AdRules/main/rules/github-hosts.conf"
curl -sL -m 30 --retry 2 "$urlgthosts" -o package/diy/luci-app-smartdns/root/etc/smartdns/hostsgithub.conf
# GitHub hosts链接地址 for mosdns
# url="https://raw.hellogithub.com/hosts"
# # 配置文件、Title
# echo "# Title: GitHub Hosts" > /tmp/gthosts.txt
# echo "# Update: $(TZ=UTC-8 date +'%Y-%m-%d %H:%M:%S')(GMT+8)" >> /tmp/gthosts.txt
# # 转化
# curl -s "$url" | grep -v "^\s*#\|^\s*$" | awk '{print ""$2" "$1}' >> /tmp/gthosts.txt
# mv /tmp/gthosts.txt package/diy/luci-app-smartdns/root/etc/smartdns/domain-set/hostsghmos.txt
# }
## add direct-domain-list
# https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt
# urlcnlist="https://raw.githubusercontent.com/ixmu/smartdns-conf/main/direct-domain-list.conf"
# curl -sL -m 30 --retry 2 "$urlcnlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/sitedirect.txt
## add proxy-domain-list
# https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt
# urlncnlist="https://raw.githubusercontent.com/ixmu/smartdns-conf/main/proxy-domain-list.conf"
# curl -sL -m 30 --retry 2 "$urlncnlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/siteproxy.txt
## add china-list
# https://raw.githubusercontent.com/pexcn/daily/gh-pages/chinalist/chinalist.txt
urlchnlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/china-list.txt"
curl -sL -m 30 --retry 2 "$urlchnlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/chnlist.txt
## add gfw list
# https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt
urlgfwlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt"
curl -sL -m 30 --retry 2 "$urlgfwlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/gfwlist.txt
## add 秋风广告规则-hosts
# urladhosts="https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/Filters/AWAvenue-Ads-Rule-hosts.txt"
# curl -sL -m 30 --retry 2 "$urladhosts"  -o package/diy/luci-app-smartdns/root/etc/AWAvenueadshosts.txt
  #去除带!符号的6行
#sed -i '/!/d' package/diy/luci-app-smartdns/root/etc/AWAvenueadshosts.txt
  # or 替换!为#
#sed -i 's/!/#/g' package/diy/luci-app-smartdns/root/etc/AWAvenueadshosts.txt
## add reject-list for mosdns
urlrejlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt"
curl -sL -m 30 --retry 2 "$urlrejlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/sitereject.txt
# ls -l package/diy/luci-app-smartdns/root/etc/smartdns

## 若不安装 v2raya 则借用 smartdns / mosdns 配置文件夹安装 xrayconfig
# # mkdir -p package/diy/mosdns/luci-app-mosdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
# # cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/xraycore.init package/diy/mosdns/luci-app-mosdns/root/etc/init.d/xray
# # mkdir -p package/diy/mosdns/luci-app-mosdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
# # cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/xraycorecfg.cst package/diy/mosdns/luci-app-mosdns/root/etc/xray/xraycfg.json

# # or
mkdir -p package/diy/luci-app-smartdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/xraycore.init package/diy/luci-app-smartdns/root/etc/init.d/xray
if [ $? -eq 0 ]; then
    echo "xrayint copied"
else
    echo "xrayint copy failed"
fi
# 2305 需要0755权限
chmod +x package/diy/mosdns/luci-app-mosdns/root/etc/init.d/xray

mkdir -p package/diy/luci-app-smartdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/xraycorecfg.cst package/diy/luci-app-smartdns/root/etc/xray/xraycfg.json
if [ $? -eq 0 ]; then
    echo "xraycfg copied"
else
    echo "xraycfg copy failed"
fi

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
