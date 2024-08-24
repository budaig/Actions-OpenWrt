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
git clone https://github.com/sbwml/packages_lang_golang -b 21.x feeds/packages/lang/golang
# use
# cp ${GITHUB_WORKSPACE}/_modFiles/golang-values.mk feeds/packages/lang/golang/golang-values.mk
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
# git clone https://github.com/sbwml/luci-app-alist.git -b master package/diy/alist
git clone https://github.com/oppen321/luci-app-alist -b main package/diy/alist
# mv package/diy/alist/alist feeds/packages/net/alist
# mv package/diy/alist/luci-app-alist feeds/luci/applications/luci-app-alist

## customize alist ver
# sleep 1
# alver=3.36.0
# alwebver=3.36.0
# alsha256=($(curl -sL https://codeload.github.com/alist-org/alist/tar.gz/v$alver | shasum -a 256))
# alwebsha256=($(curl -sL https://github.com/alist-org/alist-web/releases/download/$alwebver/dist.tar.gz | shasum -a 256))
# echo alist $alver sha256=$alsha256
# echo alist-web $alver sha256=$alwebsha256
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
# rm -rf feeds/packages/net/lucky
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

# #/etc/lucky/lucky.conf
# git clone https://github.com/sirpdboy/luci-app-lucky.git -b main package/diy/lucky
# sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.6.2
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/diy/lucky/lucky/Makefile
# sed -i '/PKG_SOURCE_VERSION:=/d' package/diy/lucky/lucky/Makefile
# cp -f ${GITHUB_WORKSPACE}/_modFiles/etcconfiglucky package/diy/lucky/luci-app-lucky/root/etc/config/lucky
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

# ##  -------------- xray ---------------------------
git clone https://github.com/yichya/openwrt-xray-geodata-cut -b master package/diy/openwrt-geodata
   #与 mosdns geodata 相同
git clone https://github.com/yichya/openwrt-xray -b master package/diy/openwrt-xray
# use custom ver
# xrver=1.8.23
# xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
# echo xray $xrver sha256=$xrsha256
# sed -i '4 s/.*/PKG_VERSION:='"$xrver"'/g;12 s/.*/PKG_HASH:='"$xrsha256"'/g' package/diy/oepnwrt-xray/Makefile

# ##  -------------- luci app xray ---------------------------
# use yicha xray status for 22.03 or up---------------
# git clone https://github.com/yichya/luci-app-xray -b master package/diy/luci-app-status
# use yicha xray status ---------------
# or use ttimasdf xray/xapp for 21.02 or up---------------
# git clone https://github.com/ttimasdf/luci-app-xray -b master package/diy/luci-app-xapp   #for 21.02
# git clone https://github.com/ttimasdf/luci-app-xray -b main package/diy/luci-app-xapp   #for 22.03 or up
# use yicha xray xapp ---------------
# ## ---------------------------------------------------------

# ## -------------- v2raya ---------------------------
# nl feeds/packages/net/v2raya/Makefile   #21.02 org ver2.1.0
rm -rf feeds/packages/net/v2raya
rm -rf feeds/luci/applications/luci-app-v2raya
git clone https://github.com/v2rayA/v2raya-openwrt -b master package/diy/v2raya
mv package/diy/v2raya/v2raya feeds/packages/net/v2raya
mv package/diy/v2raya/luci-app-v2raya feeds/luci/applications/luci-app-v2raya

# rm -rf package/diy/v2raya/v2ray-core

## customize immortalwrt orig v2raya
# nl feeds/packages/net/v2raya/Makefile
# v2aver=2.2.5.8
# v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
# v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
# echo v2raya $v2aver sha256=$v2asha256
# echo v2raya-web $v2aver sha256=$v2awebsha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' feeds/packages/net/v2raya/Makefile
# nl feeds/packages/net/v2raya/Makefile

## customize v2raya ver
sleep 1
v2aver=2.2.5.8
v2asha256=($(curl -sL https://codeload.github.com/v2rayA/v2rayA/tar.gz/v$v2aver | shasum -a 256))
v2awebsha256=($(curl -sL https://github.com/v2rayA/v2rayA/releases/download/v$v2aver/web.tar.gz | shasum -a 256))
echo v2raya $v2aver sha256=$v2asha256
echo v2raya-web $v2aver sha256=$v2awebsha256
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$v2aver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$v2asha256"'/g;59 s/	HASH:=.*/	HASH:='"$v2awebsha256"'/g' feeds/packages/net/v2raya/Makefile

# fix mijia cloud wrong dns (use xraycore)-------
cp -f ${GITHUB_WORKSPACE}/_modFiles/v2raya.init feeds/packages/net/v2raya/files/v2raya.init
if [ $? -eq 0 ]; then
    echo "v2raya.init copied"
else
    echo "v2raya.init copy failed"
fi
# sed -i 's/v2ray_bin"/v2ray_bin" "\/usr\/bin\/xray"/g;s/v2ray_confdir"/v2ray_confdir" "\/etc\/v2raya\/xray"/g' package/diy/v2raya/v2raya/files/v2raya.init
#or
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/v2raya.init -o package/diy/v2raya/v2raya/files/v2raya.init
mkdir -p feeds/luci/applications/luci-app-v2raya/root/etc/v2raya/xray || echo "Failed to create /luci-app-v2raya/root/etc/v2raya/xray"
cp -f ${GITHUB_WORKSPACE}/_modFiles/xrayconf.json feeds/luci/applications/luci-app-v2raya/root/etc/v2raya/xray/config.json
if [ $? -eq 0 ]; then
    echo "xrayconf copied"
else
    echo "xrayconf copy failed"
fi
# or
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/xrayconfig.json -o package/diy/v2raya/luci-app-v2raya/root/etc/v2raya/xray/config.json
# # go 1.21.4
# cp -f ${GITHUB_WORKSPACE}/_modFiles/100-go-mod-ver.patch package/diy/v2raya/xray-core/patches/100-go-mod-ver.patch
# if [ $? -eq 0 ]; then
    # echo "100-go-mod-ver copied"
# else
    # echo "100-go-mod-ver copy failed"
# fi
# sed -i 's/1.21.7/1.21.9/g' package/diy/v2raya/xray-core/patches/100-go-mod-ver.patch

# sleep 1
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/v2raya-static-config.js -o package/diy/v2raya/luci-app-v2raya/htdocs/luci-static/resources/view/v2raya/config.js
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/mijia-hook.sh -o package/diy/v2raya/luci-app-v2raya/root/usr/share/mijia-hook.sh
# chmod +x package/diy/v2raya/luci-app-v2raya/root/usr/share/mijia-hook.sh
# rm package/diy/v2raya/v2raya/files/v2raya.init
# curl -sL -m 30 --retry 2 https://gitlab.com/budaig/budaig.gitlab.io/-/raw/source/source/foto/v2raya02.init -o package/diy/v2raya/v2raya/files/v2raya.init
# chmod +x package/diy/v2raya/v2raya/files/v2raya.init
# fix mijia cloud ------------------------

# use custom ver ----------------
# sleep 1
# vrver=5.16.1
# vrsha256=($(curl -sL https://codeload.github.com/v2fly/v2ray-core/tar.gz/v$vrver | shasum -a 256))
# echo v2ray $vrver sha256=$vrsha256
# sed -i '8 s/.*/PKG_VERSION:='"$vrver"'/g;13 s/.*/PKG_HASH:='"$vrsha256"'/g' package/diy/v2raya/v2ray-core/Makefile

# xrver=1.8.23
# xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
# echo xray $xrver sha256=$xrsha256
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

# ## -------------- mosdns ---------------------------
# ls feeds/packages/net/mosdns
# nl feeds/packages/net/mosdns/Makefile   #ver5.1.3
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
# git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/diy/mosdns
# customize to use 5.3.x
mkdir -p package/diy/mosdns
mv -f ${GITHUB_WORKSPACE}/_modFiles/mosdns531/* package/diy/mosdns
if [ $? -eq 0 ]; then
    echo "mosdns dir copied"
else
    echo "mosdns dir copy failed"
fi
ls package/diy/mosdns

# git clone https://github.com/sbwml/v2ray-geodata -b master package/diy/v2ray-geodata
   # #与 openwrt-xray geodat 相同
# cp -f ${GITHUB_WORKSPACE}/_modFiles/mosdnsgeodataMakefile package/diy/v2ray-geodata/Makefile
# if [ $? -eq 0 ]; then
    # echo "mosdnsgeodataMakefile copied"
# else
    # echo "mosdnsgeodataMakefile copy failed"
# fi
# ## ---------------------------------------------------------

# ## -------------- smartdns ---------------------------
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns -b master package/diy/smartdns
git clone https://github.com/pymumu/luci-app-smartdns -b master package/diy/luci-app-smartdns

## update to the newest
SMARTDNS_VER=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].commit.committer.date | awk -F "T" '{print $1}' | sed 's/\"//g' | sed 's/\-/\./g'`)
SMAERTDNS_SHA=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].sha | sed 's/\"//g'`)
echo smartdns $SMARTDNS_VER sha256=$SMAERTDNS_SHA

sed -i '/PKG_MIRROR_HASH:=/d' package/diy/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/smartdns/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$SMAERTDNS_SHA"'/g' package/diy/smartdns/Makefile
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/luci-app-smartdns/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/diy/luci-app-smartdns/Makefile

## add anti-ad data
mkdir -p package/diy/luci-app-smartdns/root/etc/smartdns/domain-set || echo "Failed to create /luci-app-smartdns/root/etc/smartdns/domain-set"
# ls -dR package/diy/luci-app-smartdns/root/etc/smartdns
sleep 1
urlreject="https://anti-ad.net/anti-ad-for-smartdns.conf"
curl -sL -m 30 --retry 2 "$urlreject" -o /tmp/reject.conf
mv /tmp/reject.conf package/diy/luci-app-smartdns/root/etc/smartdns/reject.conf >/dev/null 2>&1
## add githubhosts
urlgthosts="https://raw.githubusercontent.com/hululu1068/AdRules/main/rules/github-hosts.conf"
curl -sL -m 30 --retry 2 "$urlgthosts" -o package/diy/luci-app-smartdns/root/etc/smartdns/domain-set/gthosts.conf
# ls -l package/diy/luci-app-smartdns/root/etc/smartdns

## 若不安装 v2raya 则借用 smartdns / mosdns 配置文件夹安装 xrayconfig
mkdir -p package/diy/luci-app-smartdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
cp -f ${GITHUB_WORKSPACE}/_modFiles/xray.init package/diy/luci-app-smartdns/root/etc/init.d/xray
# or
# mkdir -p package/diy/mosdns/luci-app-mosdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/xray.init package/diy/mosdns/luci-app-mosdns/root/etc/init.d/xray
if [ $? -eq 0 ]; then
    echo "xrayint copied"
else
    echo "xrayint copy failed"
fi
# 2305 需要0755权限
# chmod +x package/diy/mosdns/luci-app-mosdns/root/etc/init.d/xray

mkdir -p package/diy/luci-app-smartdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
cp -f ${GITHUB_WORKSPACE}/_modFiles/xraycfg.cst package/diy/luci-app-smartdns/root/etc/xray/xraycfg.json
# or
# mkdir -p package/diy/mosdns/luci-app-mosdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/xraycfg.cst package/diy/mosdns/luci-app-mosdns/root/etc/xray/xraycfg.json
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
