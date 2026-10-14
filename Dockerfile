# DeepSeek Harness (dsh) Web UI - Docker 镜像
# 说明:不锁版本,每次构建都安装 npm 上的最新版 @deepseek-ai/dsh
FROM node:24-slim

# 将apt-get源更换为阿里云的镜像
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 基础工具:git(工作区操作)、curl(健康检查)、socat(端口转发,见 entrypoint)
# python3/make/g++ 用于编译 node-pty 等原生模块(node-gyp 必需)
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl socat ca-certificates python3 make g++ \
 && rm -rf /var/lib/apt/lists/*


# 安装 DeepSeek Harness 最新版(不锁定版本)
# CACHEBUST:workflow 每次构建通过 build-args 传入 github.run_id,
# 在下面的 RUN 中引用它,强制 npm install 层缓存失效,
# 避免 gha 层缓存命中导致 :latest 内容永不更新(见 issue #2)
ARG CACHEBUST=0
RUN test -n "$CACHEBUST" \
 && npm install -g @deepseek-ai/dsh


# 数据目录:配置、凭据、会话都存这里(compose 挂载到宿主 ./data)
ENV DSH_HOME=/data
RUN mkdir -p /data /workspace


# dsh 的启动目录就是默认工作区
WORKDIR /workspace


COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh


EXPOSE 3080


HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3080/ >/dev/null || exit 1


ENTRYPOINT ["docker-entrypoint.sh"]
