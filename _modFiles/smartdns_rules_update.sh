#!/bin/bash

download_files() {
    # curl -o /etc/smartdns/smartdns.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/smartdns.conf
    # curl -o /etc/smartdns/hosts.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/hosts.conf
    # curl -o /etc/smartdns/blacklist-ip.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/blacklist-ip.conf
    # curl -o /etc/smartdns/proxy-domain-list.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/proxy-domain-list.conf
    curl -sL -m 30 --retry 2 https://fastly.jsdelivr.net/gh/ixmu/smartdns-conf@main/proxy-domain-list.conf -o /etc/smartdns/proxy-domain-list.conf
    # curl -o /etc/smartdns/direct-domain-list.conf https://raw.githubusercontent.com/ixmu/smartdns-conf/main/direct-domain-list.conf
    curl -sL -m 30 --retry 2 https://fastly.jsdelivr.net/gh/ixmu/smartdns-conf@main/direct-domain-list.conf -o /etc/smartdns/direct-domain-list.conf
    ##adrules
    # curl -sL -m 30 --retry 2 https://anti-ad.net/anti-ad-for-smartdns.conf -o /etc/smartdns/reject.conf
    #or
    curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/hululu1068/AdRules@main/smart-dns.conf -o /etc/smartdns/reject.conf
    ##github hosts
    curl -sL -m 30 --retry 2 https://cdn.jsdelivr.net/gh/hululu1068/AdRules@main/rules/github-hosts.conf -o /etc/smartdns/domain-set/gthosts.conf
    ##TG-Twilight ads hosts
    # curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/TG-Twilight/AWAvenue-Ads-Rule/main/Filters/AWAvenue-Ads-Rule-hosts.txt -o /etc/AWAvenueadshosts.txt
    ## IP: google fastly telegram twitter
    ##Telegram IP
    # curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/telegram.txt -o /etc/smartdns/ip-set/teleIP.txt
    ##Cloudflare IP
    # curl -sL -m 30 --retry 2 https://raw.githubusercontent.com/Loyalsoldier/geoip/release/text/cloudflare.txt -o /etc/smartdns/ip-set/cloudflareIP.txt
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
