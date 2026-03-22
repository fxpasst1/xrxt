# 第一阶段：下载器 (利用 Buildx 自动适配架构)
FROM --platform=$TARGETPLATFORM alpine:latest AS downloader

ARG TARGETARCH
WORKDIR /downloads

RUN apk add --no-cache curl unzip

RUN set -ex; \
    case "$TARGETARCH" in \
        amd64) XRAY_ARCH="64"; CF_ARCH="amd64"; XTUN_ARCH="amd64" ;; \
        arm64) XRAY_ARCH="arm64-v8a"; CF_ARCH="arm64"; XTUN_ARCH="arm64" ;; \
        arm)   XRAY_ARCH="arm32-v7a"; CF_ARCH="arm"; XTUN_ARCH="arm" ;; \
        *) echo "Unsupported arch: $TARGETARCH"; exit 1 ;; \
    esac; \
    # 下载 Cloudflared
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o cloudflared; \
    # 下载 x-tunnel
    curl -L "https://raw.githubusercontent.com/fxpasst1/xtun/main/bin/x-tunnel-linux-${XTUN_ARCH}" -o x-tunnel; \
    # 下载 Xray
    curl -L "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${XRAY_ARCH}.zip" -o xray.zip; \
    unzip -q xray.zip && mv xray xray-bin; \
    chmod +x cloudflared x-tunnel xray-bin

# 第二阶段：最终镜像
FROM --platform=$TARGETPLATFORM alpine:latest

# 安装基础运行库
RUN apk add --no-cache ca-certificates bash jq tzdata procps

WORKDIR /app

# 从下载器阶段拷贝二进制文件（这样镜像里就直接有了）
COPY --from=downloader /downloads/cloudflared /usr/local/bin/cloudflared
COPY --from=downloader /downloads/x-tunnel /usr/local/bin/x-tunnel
COPY --from=downloader /downloads/xray-bin /usr/local/bin/xray

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 环境变量默认值
ENV CF_TOKEN="" \
    XTUN_TOKEN="" \
    DOMAIN="" \
    UUID="bc986ffe-5604-41b8-9c6b-6148ebbce4e4" \
    XP=40001 \
    TP=40002 \
    MP=40003 \
    PATH_URL="/vless" \
    BEST_CF="saas.sin.fan"

ENTRYPOINT ["/entrypoint.sh"]
