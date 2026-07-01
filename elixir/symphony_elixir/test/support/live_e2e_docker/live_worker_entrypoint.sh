#!/bin/sh
# このファイルは元のApache 2.0ライセンスのコードから変更されています
# 変更日: 2026-07-01
# 変更者: totto2727
# 変更内容: live E2E worker の設定ディレクトリを OpenCode 前提へ更新

set -eu

install -d -m 700 /root/.ssh /root/.config/opencode

if [ ! -s /run/symphony/ssh/authorized_key.pub ]; then
  echo "missing authorized key at /run/symphony/ssh/authorized_key.pub" >&2
  exit 1
fi

install -m 600 /run/symphony/ssh/authorized_key.pub /root/.ssh/authorized_keys

exec /usr/sbin/sshd -D -e
