# nixos

## セットアップ

```bash
task rebuild
task lang:fix
```

## デスクトップ

- 外観
  - インターフェース: narrow
  - システムフォント: IBM Plex Sans JP
  - 等幅フォント: `PlemolJP`
  - テーマ設定 > GNOMEアプリケーションに適用: true
- パネル
  - 不透明度: 50%
- ドック
  - 自動非表示: true
  - 不透明度: 50%

## ディスプレイ

- 拡大率: 175%

## サウンド

- デバイスプロファイルの設定

## アプリケーション

- デフォルトアプリケーションの確認
- X11互換性 > 拡大率: ゲームモード

## ターミナル

- ~/.config/cosmic/com.system76.CosmicTerm/v1/profiles
  ```json
  {
      0: (
          name: "Default",
          command: "zsh",
          syntax_theme_dark: "COSMIC Dark",
          syntax_theme_light: "COSMIC Light",
          tab_title: "",
          working_directory: "/home/totto2727",
          drain_on_exit: false,
      ),
  }
  ```

## NordVPN

ブロック中: https://github.com/NixOS/nixpkgs/pull/406725

```bash
sudo nordvpn login
sudo systemctl restart nordvpn
sudo nordvpn connect
```

## Flatpak

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

## Waydroid

1. `sudo waydroid init`
2. `sudo systemctl start waydroid-container`
3. `waydroid-helper`
   1. 拡張機能 > LiteGpapps > Show > インストール
   2. 拡張機能 > ndk_translation > ndk_translation-chromeos_zork
4. 言語を変更
5. `sudo waydroid shell`
6. `ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"`
7. https://www.google.com/android/uncertified/ を開く
8. `sudo systemctl restart waydroid-container`
9. waydroidを開く

## Tailscale

1. `sudo tailscale up --ssh`