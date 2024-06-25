#!/bin/sh
# 本脚本用于解决米家无法联网
# vi /etc/v2raya/mijia-hook.sh
# chmod +x /usr/share/mijia-hook.sh
# vi /etc/init.d/v2raya
# 再start_service函数中添加append_env_arg "config" "core_hook" "/usr/share/mijia-hook.sh"
echo hook
jq '.inbounds[] |= if .tag == "transparent" then (.sniffing.domainsExcluded = ["mijia cloud","courier.push.apple.com","dlg.io.mi.com"]) else . end' /etc/v2raya/config.json > /etc/v2raya/temp.json
mv /etc/v2raya/temp.json /etc/v2raya/config.json
sleep 1