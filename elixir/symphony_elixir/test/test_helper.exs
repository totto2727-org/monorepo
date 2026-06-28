# このファイルは元のApache 2.0ライセンスのコードから変更されています
# 変更日: 2026-06-28
# 変更者: totto2727
# 変更内容: OpenCode fake support をテスト起動時に読み込むよう更新

ExUnit.start()
Code.require_file("support/snapshot_support.exs", __DIR__)
Code.require_file("support/opencode_fakes.exs", __DIR__)
Code.require_file("support/test_support.exs", __DIR__)
