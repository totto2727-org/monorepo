# nixos

## setup

```bash
task rebuild
task lang:fix
```

## desktop

- appearance
  - interface: narrow
  - system font: IBM Plex Sans JP
  - mono font: `PlemolJP`
  - thema config > apply to gnome applications: true
- panel
  - opacity: 50%
- dock
  - auto hidden: true
  - opacity: 50%

## display

- scaling: 175%

## sound

- setup device profiles

## application

- check default application
- x11 compatibility > scaling: game mode

## terminal

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

## nordvpn

blocked: https://github.com/NixOS/nixpkgs/pull/406725

```bash
sudo nordvpn login
sudo systemctl restart nordvpn
sudo nordvpn connect
```

## flatpak

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

## waydroid

1. `sudo waydroid init`
1. `sudo systemctl start waydroid-container`
1. `waydroid-helper`
   1. extension > LiteGpapps > Show > install
   1. extension > ndk_translation > ndk_translation-chromeos_zork
1. change language
1. `sudo waydroid shell`
1. `ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"`
1. open https://www.google.com/android/uncertified/
1. `sudo systemctl restart waydroid-container`
1. open waydroid

## tailscale

1. `sudo tailscale up --ssh`
