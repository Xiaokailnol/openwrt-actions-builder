#!/bin/sh

. /etc/os-release
. /lib/functions/uci-defaults.sh

[ $(uname -m) = "x86_64" ] && alias board_name="echo x86_64"
[ "$OPENWRT_BOARD" = "armsr/armv8" ] && alias board_name="echo armsr,armv8"

# theme
if [ -d "/www/luci-static/argon" ] && [ -z "$(uci -q get luci.main.pollinterval)" ]; then
    uci set luci.main.mediaurlbase='/luci-static/argon'
    uci set luci.main.pollinterval='3'
    uci commit luci
fi

devices_setup()
{
    case "$(board_name)" in
    friendlyarm,nanopi-r2c)
        uci set ota.config.api_url="https://api.kejizero.xyz/ota/nanopi-r2c.json"
        uci commit ota
        ;;
    friendlyarm,nanopi-r2s)
        uci set ota.config.api_url="https://api.kejizero.xyz/ota/nanopi-r2s.json"
        uci commit ota
        ;;
    friendlyarm,nanopi-r3s)
        uci set ota.config.api_url="https://api.kejizero.xyz/ota/nanopi-r3s.json"
        uci commit ota
        ;;
    friendlyarm,nanopi-r4s)
        uci set ota.config.api_url="https://api.kejizero.xyz/ota/nanopi-r4s.json"
        uci commit ota
        ;;
    x86_64)
        uci set ota.config.api_url="https://api.kejizero.xyz/ota/x86_64.json"
        uci commit ota
        ;;
    esac
}

# init
devices_setup

exit 0
