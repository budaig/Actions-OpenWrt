#!/bin/bash

download_files() {
    # curl -o /etc/smartdns/smartdns.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/smartdns.conf
    # curl -o /etc/smartdns/hosts.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/hosts.conf
    # curl -o /etc/smartdns/blacklist-ip.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/blacklist-ip.conf
    curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt -o /etc/smartdns/gfwlist.txt
    curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/china-list.txt -o /etc/smartdns/chnlist.txt
    # curl -o /etc/smartdns/proxy-domain-list.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/proxy-domain-list.conf
    # curl -sL -m 30 --retry 2 https://fastly.jsdelivr.net/gh/ixmu/smartdns-conf@main/proxy-domain-list.conf -o /etc/smartdns/siteproxy.txt
    # curl -o /etc/smartdns/direct-domain-list.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/direct-domain-list.conf
    # curl -sL -m 30 --retry 2 https://fastly.jsdelivr.net/gh/ixmu/smartdns-conf@main/direct-domain-list.conf -o /etc/smartdns/sitedirect.txt
    ##adrules domain list for smartdns domain-set address
    # curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/reject-list.txt -o /etc/smartdns/sitereject.txt
    # curl -sL -m 30 --retry 2 https://anti-ad.net/anti-ad-for-smartdns.conf -o /etc/smartdns/reject.conf
    #or
    # curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/hululu1068/AdRules@main/smart-dns.conf -o /etc/smartdns/reject.conf
    curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/hululu1068/AdRules@main/rules/github-hosts.conf -o /etc/smartdns/hostsgithub.conf
    ##chnroute ip for chinadns-ng
    urlchnroutelist="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chnroute/chnroute.txt"
    curl -sL -m 30 --retry 2 "$urlchnroutelist" -o /etc/chinadns-ng/chnroute.txt
    urlchnroute6list="https://raw.githubusercontent.com/pexcn/daily/gh-pages/chnroute/chnroute6.txt"
    curl -sL -m 30 --retry 2 "$urlchnroute6list" -o /etc/chinadns-ng/chnroute6.txt
    ##adrules hosts list
    # curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/hululu1068/AdRules@main/hosts.txt -o /etc/smartdns/hostsreject.txt
    ##github hosts
    curl -sL -m 30 --retry 2 https://raw.hellogithub.com/hosts -o /etc/smartdns/hostsgithub.txt
    ##github hosts for smartdns
    ##TG-Twilight ads hosts
    # curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/Filters/AWAvenue-Ads-Rule-hosts.txt -o /etc/AWAvenueadshosts.txt
    ## IP: google fastly telegram twitter
    ##Telegram IP
    # curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/telegram.txt -o /etc/smartdns/ip-set/teleIP.txt
    ##Cloudflare IP
    # curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/cloudflare.txt -o /etc/smartdns/ip-set/cloudflareIP.txt

    # curl -o /etc/mosdns/rule/cf-ipv4.txt https://www.cloudflare.com/ips-v4/ 
    # curl -o /etc/mosdns/rule/cf-ipv6.txt https://www.cloudflare.com/ips-v6/

# # GitHub hosts链接地址 for mosdns
# url="https://raw.hellogithub.com/hosts"
# # 配置文件、Title
# echo "# Title: GitHub Hosts" > /tmp/gthosts.txt
# echo "# Update: $(TZ=UTC-8 date +'%Y-%m-%d %H:%M:%S')(GMT+8)" >> /tmp/gthosts.txt
# # 转化 for mosdns
# curl -s "$url" | grep -v "^\s*#\|^\s*$" | awk '{print ""$2" "$1}' >> /tmp/gthosts.txt
# mv /tmp/gthosts.txt /etc/smartdns/hostsghmos.txt
}

restart_smartdns() {
    /etc/init.d/smartdns restart
}

while true; do
    download_files

    if [ $? -eq 0 ]; then
        restart_smartdns
        break
    else
        echo "Download failed. Retrying in 30 seconds..."
        sleep 30
    fi
done
