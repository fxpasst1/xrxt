#!/bin/bash

# --- 信号处理：确保容器能优雅退出 ---
trap "echo '接收到退出信号，正在关闭服务...'; exit 0" SIGTERM SIGINT

# --- 初始化配置 ---
[[ -z "$UUID" ]] && UUID=$(cat /proc/sys/kernel/random/uuid)
mkdir -p /etc/xray
cat > /etc/xray/config.json <<EOF
{
    "inbounds": [{
        "port": $XP, "listen": "127.0.0.1", "protocol": "vless",
        "settings": { "clients": [{"id": "$UUID"}], "decryption": "none" },
        "streamSettings": { "network": "ws", "wsSettings": {"path": "$PATH_URL"} }
    }],
    "outbounds": [{ "protocol": "freedom" }]
}
EOF

# 打印节点信息（仅启动时显示一次）
REMARKS="NAT_Node_$(date +%m%d)"
VLESS_LINK="vless://${UUID}@${BEST_CF}:443?encryption=none&security=tls&type=ws&host=${DOMAIN}&sni=${DOMAIN}&path=${PATH_URL}#${REMARKS}"
echo -e "\033[32m[INFO] 节点链接: $VLESS_LINK\033[0m"

# --- 进程守护函数 ---
run_services() {
    # 1. 启动 Xray (后台)
    while true; do
        if ! pgrep -x "xray" > /dev/null; then
            echo "[$(date)] 启动 Xray..."
            /usr/local/bin/xray run -c /etc/xray/config.json > /dev/null 2>&1 &
        fi
        sleep 5
        
        # 2. 启动 x-tunnel (后台)
        if ! pgrep -f "x-tunnel" > /dev/null; then
            echo "[$(date)] 启动 x-tunnel..."
            /usr/local/bin/x-tunnel -l ws://127.0.0.1:$TP -token $XTUN_TOKEN > /dev/null 2>&1 &
        fi
        sleep 5

        # 3. 启动 Cloudflared (前台阻塞)
        if ! pgrep -x "cloudflared" > /dev/null; then
            echo "[$(date)] 启动 Cloudflared..."
            /usr/local/bin/cloudflared tunnel --no-autoupdate --protocol http2 --metrics 0.0.0.0:$MP run --token $CF_TOKEN
        fi
        
        echo "[$(date)] 检测到主进程异常，准备重新拉起..."
        sleep 10
    done
}

run_services
