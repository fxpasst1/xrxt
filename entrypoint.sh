#!/bin/bash

# 检查必要变量
if [[ -z "$CF_TOKEN" || -z "$XTUN_TOKEN" || -z "$DOMAIN" ]]; then
    echo -e "\033[31m错误：请设置环境变量 CF_TOKEN, XTUN_TOKEN 和 DOMAIN\033[0m"
    exit 1
fi

# 自动生成 UUID
[[ -z "$UUID" ]] && UUID=$(cat /proc/sys/kernel/random/uuid)

# 生成 Xray 配置
mkdir -p /etc/xray
cat > /etc/xray/config.json <<EOF
{
    "inbounds": [{
        "port": $XP,
        "listen": "127.0.0.1",
        "protocol": "vless",
        "settings": { "clients": [{"id": "$UUID"}], "decryption": "none" },
        "streamSettings": { "network": "ws", "wsSettings": {"path": "$PATH_URL"} }
    }],
    "outbounds": [{ "protocol": "freedom" }]
}
EOF

# 打印 VLESS 链接
REMARKS="GH_Docker_NAT"
VLESS_LINK="vless://${UUID}@${BEST_CF}:443?encryption=none&security=tls&type=ws&host=${DOMAIN}&sni=${DOMAIN}&path=${PATH_URL}#${REMARKS}"
echo -e "\033[32m--- 部署成功 ---\033[0m"
echo -e "\033[36m节点链接:\033[0m $VLESS_LINK"
echo -e "\033[32m----------------\033[0m"

# 启动进程
/usr/local/bin/xray run -c /etc/xray/config.json &
/usr/local/bin/x-tunnel -l ws://127.0.0.1:$TP -token $XTUN_TOKEN &

# Cloudflared 作为前台主进程
exec /usr/local/bin/cloudflared tunnel --no-autoupdate --protocol http2 --metrics 0.0.0.0:$MP run --token $CF_TOKEN
