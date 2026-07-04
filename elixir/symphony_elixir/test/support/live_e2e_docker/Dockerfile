# このファイルは元のApache 2.0ライセンスのコードから変更されています
# 変更日: 2026-07-01
# 変更者: totto2727
# 変更内容: live E2E worker を旧バックエンドではなく OpenCode CLI 前提へ更新

FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    openssh-server \
    python3 \
    ripgrep \
  && rm -rf /var/lib/apt/lists/*

RUN install -d -m 700 /root/.ssh /root/.config/opencode /run/symphony/ssh /var/run/sshd

RUN npm install --global opencode-ai

COPY symphony-live-worker.conf /etc/ssh/sshd_config.d/symphony-live-worker.conf
COPY live_worker_entrypoint.sh /usr/local/bin/symphony-live-worker
RUN chmod 755 /usr/local/bin/symphony-live-worker

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/symphony-live-worker"]
