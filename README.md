NAT-All-In-One: 多隧道 Xray 极致集成镜像

这是一个专为 NAT VPS (小鸡) 设计的全能网络工具镜像。集成了 Cloudflared、x-tunnel 和 Xray-core，通过双隧道冗余技术，解决 NAT 环境下没有公网 IP 或端口受限的痛点。
🚀 核心特性

    三合一集成：一个容器同时运行 Xray、Cloudflared 隧道和 x-tunnel。

    多架构支持：原生支持 amd64 (普通服务器), arm64 (甲骨文/树莓派), arm/v7 (旧款 32 位 ARM)。

    自动化部署：通过 GitHub Actions 自动构建并发布至 GHCR (GitHub Container Registry)。

    轻量化：基于 Alpine Linux，体积极小，适合内存受限的 NAT 小鸡。

🛠 部署指南
1. 准备工作

在运行前，请确保你已经获取了以下信息：

    Cloudflare Tunnel Token: 在 Cloudflare Dashboard 创建隧道获取。

    x-tunnel Token: 你的 x-tunnel 认证令牌。

    域名 (Domain): 绑定到 Cloudflare 隧道的域名。

2. 一键运行

将以下命令中的变量替换为你自己的值：
Bash

docker run -d \
  --name nat-node \
  --restart always \
  -e CF_TOKEN="你的_CLOUDFLARE_TOKEN" \
  -e XTUN_TOKEN="你的_XTUN_TOKEN" \
  -e DOMAIN="你的隧道域名.com" \
  ghcr.io/你的用户名/你的仓库名:latest

3. 环境变量说明
变量名	默认值	说明
CF_TOKEN	(必填)	Cloudflare Tunnel 运行令牌
XTUN_TOKEN	(必填)	x-tunnel 认证令牌
DOMAIN	(必填)	你的节点伪装域名
UUID	随机生成	VLESS 用户 ID
BEST_CF	cf.090227.xyz	优选 IP/域名 (用于生成的节点链接)
PATH_URL	/vless	WebSocket 路径
XP	40001	Xray 内部监听端口
🔍 管理与调试

查看节点链接
运行容器后，直接查看日志即可获取生成的 VLESS 链接：
Bash

docker logs nat-node

查看运行状态
Bash

docker stats nat-node

进入容器内部
Bash

docker exec -it nat-node /bin/bash

📂 项目架构

    Dockerfile: 多阶段构建，自动适配 CPU 架构。

    entrypoint.sh: 容器启动脚本，负责配置生成与多进程守护。

    .github/workflows/: GitHub Actions 自动构建流水线。

⚖️ 免责声明

本工具仅供网络技术交流与内部自动化测试使用。请在遵守当地法律法规的前提下使用。
💡 下一步建议

    设置为公开：如果你的镜像在 GHCR 是私有的，记得在 GitHub 仓库的 Packages 设置里将其改为 Public，否则 VPS 无法直接 pull。

    自定义优选：你可以通过修改 -e BEST_CF="你的域名" 来指定你自己的 Cloudflare 优选地址。
