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
package/feeds/luci/luci-app-ssr-plus
package/feeds/luci/luci-app-vssr
feeds/packages/net/v2ray-geodata
feeds/packages/net/v2ray-core
feeds/packages/net/v2ray-plugin
feeds/packages/net/xray-plugin
feeds/packages/net/xray-core
feeds/packages/lang/golang
feeds/packages/net/adguardhome
package/feeds/telephony/asterisk
"

for cmd in $del_data;
do
 rm -rf $cmd
 echo "Deleted $cmd"
done

# ## update golang to 21.x
git clone https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang

# ## -------------- adguardhome ---------------------------
# rm -rf feeds/packages/net/adguardhome
rm -rf feeds/luci/applications/luci-app-adguardhome
git clone https://github.com/xiaoxiao29/luci-app-adguardhome -b master package/diy/adguardhome
# sleep 1
# aghver=0.107.51
# aghsha256=($(curl -sL https://github.com/AdguardTeam/AdGuardHome/releases/download/v$aghver/AdGuardHome_linux_arm64.tar.gz | shasum -a 256))
# echo $aghsha256
# sed -i '10 s/.*/PKG_VERSION:='"$aghver"'/g;17 s/.*/PKG_MIRROR_HASH:='"$aghsha256"'/g' package/diy/adguardhome/AdguardHome/Makefile

# # mkdir -p package/diy/adguardhome/etc/config/adGuardConfig || echo "Failed to create /adguardhome/etc/config/adGuardConfig"
# # curl -sL -m 30 --retry 2 https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_arm64.tar.gz -o /tmp/AdGuardHome_linux_arm64.tar.gz && tar -xzf /tmp/AdGuardHome_linux_arm64.tar.gz -C /tmp && mv /tmp/AdGuardHome/AdGuardHome package/diy/adguardhome/etc/config/adGuardConfig/AdGuardHome

# ## ---------------------------------------------------------

# ## -------------- alist ---------------------------
# replace alist
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
# alist 3.36 requires go 1.22
git clone https://github.com/sbwml/luci-app-alist.git -b master package/diy/alist

## customize alist ver
# sleep 1
# alver=3.32.0
# alwebver=3.32.0
# alsha256=($(curl -sL https://codeload.github.com/alist-org/alist/tar.gz/v$alver | shasum -a 256))
# alwebsha256=($(curl -sL https://github.com/alist-org/alist-web/releases/download/$alwebver/dist.tar.gz | shasum -a 256))
# echo alist $alver sha256=$alsha256
# echo alist-web $alver sha256=$alwebsha256
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$alver"'/g;s/PKG_HASH:=.*/PKG_HASH:='"$alsha256"'/g;26 s/  HASH:=.*/  HASH:='"$alwebsha256"'/g' package/diy/alist/Makefile

# change default port: version 3.33.0 and up
# sed -i 's/5244/5246/g' package/diy/alist/files/alist.config
# sed -i 's/5244/5246/g' package/diy/alist/files/alist.init
# change default port: version 3.32.0 and below
# sed -i 's/5244/5246/g' package/diy/alist/luci-app-alist/root/etc/config/alist
# sed -i 's/5244/5246/g' package/diy/alist/luci-app-alist/root/etc/init.d/alist
# ## ---------------------------------------------------------

# ## -------------- ikoolproxy ---------------------------
# git clone -b main https://github.com/ilxp/luci-app-ikoolproxy.git package/diy/luci-app-ikoolproxy
## add video rule
sleep 1
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
# sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.6.2
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/diy/lucky/lucky/Makefile

# wget https://github.com/gdy666/lucky-files$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
lkver=2.10.8
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/lucky\/releases\/download\/v/lucky-files\/raw\/main\//g' package/diy/lucky/lucky/Makefile

   #/etc/lucky/lucky.conf
# git clone https://github.com/sirpdboy/luci-app-lucky.git -b main package/diy/lucky
# sleep 1
# ## customize lucky ver
# # wget https://www.daji.it:6/files/$(PKG_VERSION)/$(PKG_NAME)_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
# lkver=2.6.2
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:='"$lkver"'/g;s/github.com\/gdy666\/lucky\/releases\/download\/v/www.daji.it\:6\/files\//g' package/diy/lucky/lucky/Makefile
# sed -i '/PKG_SOURCE_VERSION:=/d' package/diy/lucky/lucky/Makefile

# cat package/diy/lucky/lucky/Makefile
# ## ---------------------------------------------------------

# ## add chatgpt-web
# rm -rf feeds/packages/net/luci-app-chatgpt-web
# rm -rf feeds/luci/applications/luci-app-chatgpt-web
git clone https://github.com/sirpdboy/luci-app-chatgpt-web -b main package/diy/chatgpt-web

# ##  -------------- xray ---------------------------
git clone https://github.com/yichya/openwrt-xray-geodata-cut -b master package/diy/openwrt-geodata
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
# use yicha xray status ---------------
# ## ---------------------------------------------------------

# ## -------------- mosdns ---------------------------
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/diy/mosdns
git clone https://github.com/sbwml/v2ray-geodata -b master package/diy/v2ray-geodata
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
ls -l package/diy/luci-app-smartdns/root/etc/smartdns

## 若不安装 v2raya 则借用 smartdns / mosdns 配置文件夹安装 xrayconfig
# mkdir -p package/diy/luci-app-smartdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/xray.init package/diy/luci-app-smartdns/root/etc/init.d/xray
# or
mkdir -p package/diy/mosdns/luci-app-mosdns/root/etc/init.d || echo "Failed to create /luci-app-smartdns/root/etc/init.d"
cp -f ${GITHUB_WORKSPACE}/_modFiles/xray.init package/diy/mosdns/luci-app-mosdns/root/etc/init.d/xray
if [ $? -eq 0 ]; then
    echo "xrayint copied"
else
    echo "xrayint copy failed"
fi
# mkdir -p package/diy/luci-app-smartdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
# cp -f ${GITHUB_WORKSPACE}/_modFiles/xraycfg.cst package/diy/luci-app-smartdns/root/etc/xray/xraycfg.json
# or
mkdir -p package/diy/mosdns/luci-app-mosdns/root/etc/xray || echo "Failed to create /luci-app-smartdns/root/etc/xray"
cp -f ${GITHUB_WORKSPACE}/_modFiles/xraycfg.cst package/diy/mosdns/luci-app-mosdns/root/etc/xray/xraycfg.json
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

# CONFIG_TARGET_mediatek_filogic_DEVICE_xiaomi_redmi-router-ax6000=y
grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/' > DEVICE_NAME
cat DEVICE_NAME
# xiaomi_redmi-router-ax6000

grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*TARGET_.*_(.*)_DEVICE_.*=y/\1/' > TARGET_NAME
cat TARGET_NAME
# filogic

# sleep 5

rm -rf bin tmp build_dir