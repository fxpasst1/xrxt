FROM --platform=$TARGETPLATFORM alpine:latest

# 安装必要依赖
RUN apk add --no-cache ca-certificates curl bash jq tzdata procps

WORKDIR /app

# 环境变量默认值
ENV CF_TOKEN="" \
    XTUN_TOKEN="" \
    DOMAIN="" \
    UUID="62414b2c-a700-41ce-a265-2c92d3c055f3" \
    XP=40001 \
    TP=40002 \
    MP=40003 \
    PATH_URL="/vless" \
    BEST_CF="saas.sin.fan"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 多架构二进制下载逻辑
ARG TARGETARCH
RUN set -ex; \
    case "$TARGETARCH" in \
        amd64) XRAY_ARCH="64"; CF_ARCH="amd64"; XTUN_ARCH="amd64" ;; \
        arm64) XRAY_ARCH="arm64-v8a"; CF_ARCH="arm64"; XTUN_ARCH="arm64" ;; \
        arm)   XRAY_ARCH="arm32-v7a"; CF_ARCH="arm"; XTUN_ARCH="arm" ;; \
        *) echo "Unsupported arch: $TARGETARCH"; exit 1 ;; \
    esac; \
    # Cloudflared
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared; \
    # x-tunnel
    curl -L "https://raw.githubusercontent.com/fxpasst1/xtun/main/bin/x-tunnel-linux-${XTUN_ARCH}" -o /usr/local/bin/x-tunnel; \
    # Xray
    curl -L "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip" -o /tmp/xray.zip; \
    unzip -q -o /tmp/xray.zip -d /tmp/xray_temp; \
    cp -f $(find /tmp/xray_temp -type f -name "xray") /usr/local/bin/xray; \
    chmod +x /usr/local/bin/*; \
    rm -rf /tmp/*

ENTRYPOINT ["/entrypoint.sh"]
