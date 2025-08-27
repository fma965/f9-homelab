#!/bin/bash
if [ -f /root/skip ]; then
  echo "**** Skip File (/root/skip) Found, Skipping Package Installation! ****"
  exit 0
fi
echo "**** Adding 1Password Keyring ****"
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
  tee /etc/apt/sources.list.d/1password.list && \
  mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
  curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
  tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
  mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
  curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
  gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

echo "**** Adding Github Desktop Keyring (shiftkey/desktop) ****"
wget -qO - https://mirror.mwt.me/shiftkey-desktop/gpgkey | gpg --dearmor | tee /usr/share/keyrings/mwt-desktop.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/mwt-desktop.gpg] https://mirror.mwt.me/shiftkey-desktop/deb/ any main" > /etc/apt/sources.list.d/mwt-desktop.list

echo "**** Adding Discord PPA (Javinator9889/Discord-PPA) ****"
curl -sS "https://keyserver.ubuntu.com/pks/lookup?op=get&options=mr&search=0x08633B4AAAEB49FC" | gpg --dearmor --output /usr/share/keyrings/javinator9889-ppa-keyring.gpg
tee /etc/apt/sources.list.d/javinator9889-ppa.list <<< "deb [arch=amd64 signed-by=/usr/share/keyrings/javinator9889-ppa-keyring.gpg] https://ppa.javinator9889.com all main"

echo "**** Installing Microsoft VS Code ****"
wget --progress=dot:giga 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' -O /tmp/code_latest_amd64.deb
debconf-set-selections <<< "code code/add-microsoft-repo boolean true"
DEBIAN_FRONTEND=noninteractive apt install -y /tmp/code_latest_amd64.deb

echo "**** Installing Zen (Officiall Install Script) ****"
/bin/bash -c "$(curl -fsSL https://updates.zen-browser.app/install.sh)"

echo "**** Installing Freelens ****"
curl -s https://api.github.com/repos/freelensapp/freelens/releases/latest \
| grep "browser_download_url.*amd64.deb" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget --progress=dot:giga -i -
dpkg -i *.deb

echo "**** Installing 1password-cli 1password github-desktop discord ****"
apt update
apt-get install -y 1password-cli 1password github-desktop discord

echo "**** Removing Chromium ****"
apt-get purge -y chromium
apt-get autoremove -y

echo "**** Setting flag ****"
touch /root/skip