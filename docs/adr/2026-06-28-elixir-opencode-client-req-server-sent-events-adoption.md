---
confirmed: true
scope: general
---

# ADR: Elixir OpenCode client の SSE 処理に req_server_sent_events を採用

- **Filed at:** 2026-06-28
- **Filer:** implementer
- **Originating step:** Elixir OpenCode client dependency adoption and risk review
- **Storage path:** docs/adr/2026-06-28-elixir-opencode-client-req-server-sent-events-adoption.md

## Status

`Accepted` — `elixir/package/opencode_client` の OpenCode `/event` Server-Sent Events (SSE) 受信処理では、`req_server_sent_events` を採用する。ただし、本 ADR の「Constraints going forward」に記録する DoS 緩和策を実装時の不変条件とする。

## Context

`elixir/package/opencode_client` は OpenCode Server の `/event` endpoint から SSE を購読し、受信した frame payload を JSON decode して利用する必要がある。既存の HTTP client は `Req` であり、SSE の frame 分割・field parsing・chunk 境界を跨ぐ buffer 管理を自前実装すると、仕様漏れや DoS 境界の見落としが起きやすい。

候補ライブラリ `req_server_sent_events` (`sgerrand/ex_req_server_sent_events`, `~> 0.2.1`) について、GitHub upstream source を clone し、実装・テスト・リスクを確認した。確認対象には `ReqServerSentEvents.attach/2`, `Frame.split/1`, `Frame.parse/1`, `Internal.decode_chunk/3`, `CollectableWrapper` を含めた。

確認結果の要点:

- runtime 実装は小さく、`Req` の streaming hook に SSE decoder を差し込む wrapper である。
- parser は `event`, `data`, `id`, `retry`, comment を binary として扱い、危険な動的 atom 生成は見当たらない。
- `System.cmd`, `Port.open`, `Code.eval`, `File.*`, NIF, 外部コマンド実行、任意コードロードに該当する処理は見当たらない。
- `mix format --check-formatted` は成功した。
- dependency 取得と full test は、監査環境の Hex / Elixir 組み合わせに起因する `Protocol.__concat__/2` エラーで完走できなかったため、parser / decoder の境界 smoke check を直接実行して成功を確認した。
- `max_frame_size` は存在するが、未完了 `leftover` buffer への guard であり、完全な frame size 上限ではない。

## Decision

### D-1: `req_server_sent_events` を採用する

| Option | 概要 | 採否 | 理由 |
| --- | --- | --- | --- |
| `req_server_sent_events` | `Req` plugin として SSE chunk を `%ReqServerSentEvents.Frame{}` に decode する | **採用** | 既存 HTTP client (`Req`) と自然に統合でき、実装が小さく、SSE parsing の主要仕様を既に扱っている |
| 自前 SSE parser | `/event` 専用に frame splitting / parsing / buffering を実装する | 却下 | chunk 境界・CRLF/CR/LF delimiter・BOM・`retry`/`id` 等の仕様処理を再実装する保守コストとバグリスクが高い |
| Raw streaming のみ | `Req` の raw chunk を呼び出し側で処理する | 却下 | 呼び出し側に SSE parsing 責務が漏れ、API とテスト境界が不明瞭になる |

### D-2: 採用は localhost OpenCode `/event` 用途に限定して評価する

本 ADR の安全性判断は、OpenCode Server の既定用途である localhost `/event` SSE を読む client 用途に対する判断である。不信な外部 SSE endpoint を一般用途で購読するための hardening 済み streaming parser としては扱わない。

### D-3: `max_frame_size` と downstream validation を必須の緩和策にする

`req_server_sent_events` の `:max_frame_size` は未完了 frame buffer の無制限成長を抑えるが、完全な DoS 境界ではない。そのため、採用時は以下を組み合わせる。

- `ReqServerSentEvents.attach(max_frame_size: ...)` を明示する。
- decoded frame / JSON payload のサイズ・型・期待 event 種別を client 側で検証する。
- infinite stream を collectable list に回収しない。
- 高頻度 stream では `into: :self` の mailbox 蓄積に注意し、consumer 側 timeout / task 監視で異常終了を扱う。

## Consequences

- **Newly added:** `elixir/package/opencode_client` は SSE parsing dependency として `req_server_sent_events ~> 0.2.1` を保持する。OpenCode `/event` 用の frame decode はこの dependency に委譲する。
- **Existing impact:** `OpencodeClient.EventStream` は `ReqServerSentEvents.attach/2` を使って stream frame を受け取り、payload JSON decode のみを担当する。dependency の parser 挙動 (`partial frame` の破棄、unknown field の無視、`retry` parsing 等) を前提にする。
- **Constraints going forward:**
  - `ReqServerSentEvents.attach/2` には `max_frame_size` を明示する。
  - `max_frame_size` を hard cap と誤解しない。巨大な complete frame や大量 event への downstream validation を別途維持する。
  - user-supplied URL をそのまま SSE 接続先にしない。OpenCode localhost endpoint など期待された接続先に限定する。
  - `into: :self` を使う場合は mailbox backpressure がないことを前提に、request task の監視・timeout・終了処理を明示する。
  - full dependency security posture は consuming app の `mix.lock` で解決される `req` / HTTP stack versions に依存するため、lockfile 更新時に再確認する。

## Risk Record

| Risk | Severity | Finding | Mitigation |
| --- | --- | --- | --- |
| 未完了 frame の unbounded buffering | Medium | `max_frame_size` default は `nil` で、delimiter が来ない stream では buffer が伸び得る | `attach(max_frame_size: ...)` を必須化する |
| complete frame size の bypass | Medium-High | `Internal.decode_chunk/3` は split 後の `leftover` を check するため、1 chunk 内の巨大 complete frame は上限として完全には止められない | decoded payload size / expected schema / event kind を client 側で検証する |
| mailbox pressure | Low-Medium | `into: :self` は frame ごとに `send/2` し、consumer が遅い場合 backpressure がない | `into: fun` を優先し、`:self` 利用時は task 監視と timeout を置く |
| partial frame discard | Low | stream end 時の未完了 frame は flush されず破棄される | SSE frame は delimiter で完了するものとして扱い、欠落を許容できない用途では protocol-level retry を検討する |
| malformed binary / parser exception | Low | `String.*` parser のため、不正 binary で例外になる可能性がある | 例外を stream failure として扱い、制御された retry / abort にする |

## Related

- `elixir/package/opencode_client/mix.exs` — `{:req_server_sent_events, "~> 0.2.1"}` dependency declaration
- `elixir/package/opencode_client/lib/opencode_client/event_stream.ex` — OpenCode `/event` SSE wrapper
- Upstream repository: <https://github.com/sgerrand/ex_req_server_sent_events>
- Upstream source references:
  - `ReqServerSentEvents.attach/2`: <https://github.com/sgerrand/ex_req_server_sent_events/blob/1ff5de662605f8550ec383873e93bdadc7fb2e74/lib/req_server_sent_events.ex#L67-L78>
  - `Frame.split/1` / `Frame.parse/1`: <https://github.com/sgerrand/ex_req_server_sent_events/blob/1ff5de662605f8550ec383873e93bdadc7fb2e74/lib/req_server_sent_events/frame.ex>
  - `Internal.decode_chunk/3` and `max_frame_size` check: <https://github.com/sgerrand/ex_req_server_sent_events/blob/1ff5de662605f8550ec383873e93bdadc7fb2e74/lib/req_server_sent_events/internal.ex>
