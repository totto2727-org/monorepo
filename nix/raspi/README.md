# raspi

## tailscale

```bash
ssh totto2727@totto2727-raspi
sudo nmcli dev wifi connect totto2727 --ask
sudo apt install -y ufw
sudo systemctl enable ufw
sudo ufw enable
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh
sudo systemctl disable sshd
sudo apt install wakeonlan
```
