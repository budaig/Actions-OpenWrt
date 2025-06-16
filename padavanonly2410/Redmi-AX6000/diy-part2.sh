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

# pushd feeds/packages/net/xray-core/tools/po2lmo
# make && sudo make install
# popd
# sleep 3

del_data="
package/feeds/luci/luci-app-passwall
package/feeds/luci/luci-app-passwall2
package/feeds/luci/luci-app-ssr-plus
package/feeds/luci/luci-app-vssr
package/network/utils/fullconenat-nft
feeds/packages/net/geoview
feeds/packages/net/sing-box
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
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# ## -------------- adguardhome ---------------------------
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
git clone https://github.com/xiaoxiao29/luci-app-adguardhome -b master package/diy/adguardhome
# mv package/diy/adguardhome/AdGuardHome feeds/packages/net/adguardhome
# mv package/diy/adguardhome/luci-app-adguardhome feeds/luci/applications/luci-app-adguardhome

# sleep 1
# aghver=0.107.61
# aghsha256=($(curl -sL https://github.com/AdguardTeam/AdGuardHome/releases/download/v$aghver/AdGuardHome_linux_arm64.tar.gz | shasum -a 256))
# echo adguardhome $aghver sha256=$aghsha256
# sed -i '10 s/.*/PKG_VERSION:='"$aghver"'/g;17 s/.*/PKG_MIRROR_HASH:='"$aghsha256"'/g' package/diy/adguardhome/AdguardHome/Makefile
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

# cat package/diy/lucky/lucky/Makefile
# ## ---------------------------------------------------------


# ## add OpenAppFilter oaf
rm -rf feeds/luci/applications/luci-app-appfilter
rm -rf feeds/packages/net/open-app-filter
git clone -b master https://github.com/destan19/OpenAppFilter.git package/diy/OpenAppFilter


# ## add parentcontrol
# git clone -b main https://github.com/sirpdboy/luci-app-parentcontrol package/diy/parentcontrol
git clone -b main https://github.com/budaig/luci-app-parentcontrol package/diy/parentcontrol
# git clone -b main https://github.com/dsadaskwq/luci-app-parentcontrol package/diy/parentcontrol   #(已删)
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
# xrver=25.3.6
# # # xrver=25.1.30
# xrsha256=($(curl -sL https://codeload.github.com/XTLS/Xray-core/tar.gz/v$xrver | shasum -a 256))
# echo xray $xrver sha256=$xrsha256
# sed -i '4 s/.*/PKG_VERSION:='"$xrver"'/g;12 s/.*/PKG_HASH:='"$xrsha256"'/g' package/diy/openwrt-xray/Makefile

##  -------------- luci app xray ---------------------------
rm -rf feeds/luci/applications/luci-app-xray || echo "Failed to delete /luci-app-xray"

## yicha xray xstatus luci for 22.03 and up---------------
# git clone https://github.com/yichya/luci-app-xray -b master package/diy/luci-app-xstatus
# # disable auto start
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2xapp-xstatus/etcconfigxstatus.conf package/diy/luci-app-xstatus/core/root/etc/config/xray_core
# if [ $? -eq 0 ]; then
    # echo "xstatus.conf copied"
# else
    # echo "xstatus.conf copy failed"
# fi
# yicha xray xstatus ---------------
# ## ---------------------------------------------------------


# ## --------------- homeproxy + sing-box + chinadns-ng -----------------------------
# 使用 sing-box 需要 +geoview
# rm -rf feeds/packages/net/geoview
# git clone -b master https://github.com/snowie2000/geoview.git package/diy/geoview

# rm -rf feeds/packages/net/sing-box

# git clone https://github.com/immortalwrt/homeproxy -b main package/diy/homeproxy

# git clone https://github.com/lxiaya/openwrt-homeproxy -b main package/diy/singbox #(250609 chinadns-ng PKG_VERSION:=2025.03.27 sing-box 1.11.6   immoralwrt23.05 chinadns-ng PKG_VERSION:=2024.10.14)

# rm -rf package/diy/singbox/luci-app-homeproxy
# rm -rf package/diy/singbox/sing-box

## customize singbox ver
# sleep 1
# sbxver=1.11.13
# sbxsha256=($(curl -sL =https://codeload.github.com/SagerNet/sing-box/tar.gz/v$sbxver | shasum -a 256))
# echo sing-box v$sbxver sha256=$sbxsha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$sbxver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$sbxsha256"'/g' package/diy/singbox/sing-box/Makefile

# chng_ver=2024.11.17
# chng_SHA256=($(curl -sL https://github.com/zfl9/chinadns-ng/releases/download/$chng_ver/chinadns-ng+wolfssl@aarch64-linux-musl@generic+v8a@fast+lto | shasum -a 256))
# # echo chinadns-ng v$chng_ver sha256=$chng_SHA256
# sed -i '6 s/.*/PKG_VERSION:='"$chng_ver"'/g;12 s/.*/PKG_HASH:='"$chng_SHA256"'/g' package/diy/homeproxy/chinadns-ng/Makefile
# echo chinadns-ng v$chng_ver sha256=$chng_SHA256
# ## ---------------------------------------------------------


# ## -------------- Dae   内核 >= 5.17 (immortalwrt 已包含) #As a successor of v2rayA, dae abandoned v2ray-core to meet the needs of users more freely.# ---------------------------

rm -rf package/feeds/packages/daed
rm -rf feeds/luci/applications/luci-app-daed

# OpenWrt Official 23.05/SNAPSHOT
# git clone -b main https://github.com/sbwml/luci-app-dae package/diy/dae
# git clone https://github.com/sbwml/v2ray-geodata package/diy/v2ray-geodata

# OpenWrt official 24.10/SnapShots
git clone -b master https://github.com/QiuSimons/luci-app-daed package/diy/dae
sed -i 's/    +kmod-veth +v2ray-geoip +v2ray-geosite/    +kmod-veth/g' package/diy/daed/Makefile
# ## ---------------------------------------------------------


# ## -------------- v2raya ---------------------------
# nl feeds/packages/net/v2raya/Makefile   #23.05 org ver2.2.5.7
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

# rm -rf package/diy/v2raya/luci-app-v2raya
# rm -rf package/diy/v2raya/v2raya

## customize ca ver
# caver=20241223
# casha256=($(curl -sL https://ftp.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_$caver.tar.xz | shasum -a 256))
# echo ca-certificates v$caver sha256=$casha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$caver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$casha256"'/g' package/diy/v2raya/ca-certificates/Makefile
# nl feeds/packages/net/v2raya/Makefile
# ## ---------------------------------------------------------

# rm -rf package/network/utils/fullconenat-nft
# git clone https://github.com/sbwml/nft-fullcone -b master package/diy/nftfullcone   #https://github.com/yyjeqhc/nft_fullcone


# ## -------------- chinadns-ng ---------------------------
# rm -rf feeds/packages/net/chinadns-ng   #(241025 PKG_VERSION:=2023.10.28)
# rm -rf feeds/luci/applications/luci-app-chinadns-ng 

# git clone https://github.com/izilzty/luci-app-chinadns-ng -b master package/diy/luci-app-chinadns-ng
# git clone https://github.com/pexcn/openwrt-chinadns-ng -b luci package/diy/luci-app-chinadns-ng  #(241025 未适配 2.0 的新功能)

# git clone https://github.com/pexcn/openwrt-chinadns-ng -b master package/diy/chinadns-ng  #(241025 PKG_VERSION:=2023.10.28   未适配 2.0 的新功能   PKG_VERSION:=2024.10.14 https://github.com/zfl9/chinadns-ng/commit/39d4881f83fa139b52cff9d8e306c4313bf758ad)

# git clone https://github.com/izilzty/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241025 PKG_VERSION:=2023.06.05)
# git clone https://github.com/xiechangan123/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241025 PKG_VERSION:=2024.10.14)
# git clone https://github.com/muink/openwrt-chinadns-ng -b master package/diy/chinadns-ng #(241025 PKG_VERSION:=2024.10.14)

#cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/ver2Makefile package/diy/chinadns-ng/Makefile
#if [ $? -eq 0 ]; then
#    echo "chinadns-ng.Makefile copied"
#else
#    echo "chinadns-ng.Makefile copy failed"
#fi
#cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/chinadns-ng.init package/diy/chinadns-ng/files/chinadns-ng.init
#if [ $? -eq 0 ]; then
#    echo "chinadns-ng.init copied"
#else
#    echo "chinadns-ng.init copy failed"
#fi
# rm package/diy/chinadns-ng/files/chinadns-ng.init
#cp -f ${GITHUB_WORKSPACE}/_modFiles/2chinadns-ng/etcchinadnsconfig.conf package/diy/chinadns-ng/files/config.conf
#if [ $? -eq 0 ]; then
#    echo "chinadns-ng config.conf copied"
#else
#    echo "chinadns-ng config.conf copy failed"
#fi
# ## ---------------------------------------------------------


# ## -------------- smartdns ---------------------------
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
git clone https://github.com/pymumu/openwrt-smartdns -b master package/diy/smartdns   #feeds/packages/net/smartdns
git clone https://github.com/pymumu/luci-app-smartdns -b master package/diy/luci-app-smartdns   #feeds/luci/applications/luci-app-smartdns

## update to the newest
SMARTDNS_VER=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].commit.committer.date | awk -F "T" '{print $1}' | sed 's/\"//g' | sed 's/\-/\./g'`)
SMAERTDNS_SHA=$(echo -n `curl -sL https://api.github.com/repos/pymumu/smartdns/commits | jq .[0].sha | sed 's/\"//g'`)
echo smartdns v$SMARTDNS_VER sha=$SMAERTDNS_SHA

cp -f ${GITHUB_WORKSPACE}/_modFiles/2smartdns/openwrtsmartdns45-bk.Makefile package/diy/smartdns/Makefile
if [ $? -eq 0 ]; then
    echo "smartdns45.Makefile copied"
else
    echo "smartdns45.Makefile copy failed"
fi

sed -i '/PKG_MIRROR_HASH:=/d' package/diy/smartdns/Makefile   #feeds/packages/net/smartdns/Makefile
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$SMARTDNS_VER"'/g' package/diy/smartdns/Makefile   #feeds/packages/net/smartdns/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:='"$SMAERTDNS_SHA"'/g' package/diy/smartdns/Makefile   #feeds/packages/net/smartdns/Makefile
sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' package/diy/luci-app-smartdns/Makefile   #feeds/luci/applications/luci-app-smartdns/Makefile

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
# urlreject="https://raw.githubusercontent.com/hululu1068/AdGuard-Rule/adrules/smart-dns.conf"
# curl -sL -m 30 --retry 2 "$urlreject" -o /tmp/reject.conf
# mv /tmp/reject.conf package/diy/luci-app-smartdns/root/etc/smartdns/reject.conf >/dev/null 2>&1
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
urlrejlist="https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt"
curl -sL -m 30 --retry 2 "$urlrejlist" -o package/diy/luci-app-smartdns/root/etc/smartdns/sitereject
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

## 借用 smartdns / mosdns 配置文件夹安装 nft 自启
# mkdir -p package/diy/luci-app-smartdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2nft/nft package/diy/luci-app-smartdns/root/etc/init.d/nft
# if [ $? -eq 0 ]; then
    # echo "nft copied"
# else
    # echo "nft copy failed"
# fi
# chmod +x package/diy/luci-app-smartdns/root/etc/init.d/nft

# mkdir -p package/diy/luci-app-smartdns/root/etc/nftables.d || echo "Failed to create /luci-app-smartdns/root/etc/nftables.d"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/2nft/openwrt-nft-ruleset.conf package/diy/luci-app-smartdns/root/etc/nftables.d/openwrt-nft-ruleset.conf
# if [ $? -eq 0 ]; then
    # echo "openwrt-nft-ruleset copied"
# else
    # echo "openwrt-nft-ruleset copy failed"
# fi

# ## ---------------------------------------------------------

# ## replace a theme
rm -rf ./feeds/luci/themes/luci-theme-argon
git clone -b master https://github.com/jerrykuku/luci-theme-argon.git ./feeds/luci/themes/luci-theme-argon
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

# CONFIG_TARGET_mediatek_filogic_DEVICE_xiaomi_redmi-router-ax6000=y
# grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/' > DEVICE_NAME
# grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_([^=]+)=y$/\1/' > DEVICE_NAME
# cat DEVICE_NAME
# xiaomi_redmi-router-ax6000

# grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*TARGET_.*_(.*)_DEVICE_.*=y/\1/' > TARGET_NAME
# cat TARGET_NAME
# mtk7986

# sleep 5

# ls -al tmp/
# ls -al tmp/info/

# rm -rf tmp/info/.packageinfo*
# ls -al tmp/info/
