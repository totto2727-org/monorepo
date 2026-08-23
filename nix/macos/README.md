# mac

## setup mac

### accessibility > point controll > trackpad

- max scroll speed
- enable drag by trackpad

### accessibility > point controll > mause

- max wheel speed
- max scroll speed
- enable drag by trackpad

### control center

- optimize

### desktop and dock

- enable auto hidden
- disable used apps

### do not disturb

9:00~20:00

### trackpad

- speed level 6
- click level low

### keyboard

- repeat speep max

#### keyboard shortcut

- remove ctrl + space shortcut
- enable default function key
- change language by capslock
- use slash and backslash
- disable input znnkaku number

```bash
# require reboot
defaults write -g ApplePressAndHoldEnabled -bool false
```

## rename computer name

- rename totto2727
- reboot

## setup brew

https://brew.sh/

## setup nix

https://docs.determinate.systems

```bash
curl -L https://raw.githubusercontent.com/totto2727-dotfiles/nix/refs/heads/main/flake.nix > flake.nix
curl -L https://github.com/totto2727-dotfiles/nix/blob/main/flake.lock > flake.lock
nix run nix-darwin -- switch --flake .
```

## setup gh

```bash
gh auth login
```

## setup chezmoi

```bash
chezmoi init --apply https://github.com/totto2727-dotfiles/chezmoi.git
```

## setup nix-repository

```bash
rm flake.nix flake.lock
gh repo clone totto2727-dotfiles/nix
cd nix
task rebuild
```

## setup base app

- open 1password
- open Edge
  - enable Kagi extension
  - change search engine to Kagi
  - change home button to Kagi
- open and login logi-options+
  - restore backup

## gpg

- <https://christina04.hatenablog.com/entry/create-gpg-master-key-and-subkey>
- <https://text.baldanders.info/remark/2019/10/openpgp-public-keys-in-github/>

## setup karabiner driver and kanata

https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/blob/main/dist/Karabiner-DriverKit-VirtualHIDDevice-6.9.0.pkg

```bash
/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
```

```bash
karabiner
# split terminal
kanata
```

## VSCode(Cursor, Antigravity)

### install vscode extensions

```bash
# mac/vscode
jq -r '.[]' extentions.json | xargs -I {} cursor --install-extension {}
```

### update extension list

```bash
# mac/vscode
cursor --list-extensions | jq -R -s 'split("\n") | map(select(length > 0))' > extensions.json
```
