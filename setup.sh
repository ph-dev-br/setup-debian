#!/bin/bash

set -e

#===== Packages Managers
# Install required packages and dev tools
sudo apt update && sudo apt install -y \
  build-essential \
  curl \
  distrobox \
  docker.io \
  docker-compose \
  flatpak \
  git \
  libvirt-daemon-system \
  podman \
  podman-toolbox \
  qemu-system \
  qemu-utils \
  virt-manager

# HomeBrew
if ! command -v brew; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# fp-appimages-updater
if ! command -v fp-appimages-updater; then
  curl -sL https://fau.fpt.icu/i | bash -s -- --user --nosystemd
fi

# Add remote flatpak
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

#===== Softwares
# VS Code
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >/tmp/microsoft-keyring.gpg
sudo install -o root -g root -m 644 /tmp/microsoft-keyring.gpg /usr/share/keyrings/microsoft-keyring.gpg
sudo tee /etc/apt/sources.list.d/vscode.sources <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Enabled: yes
Signed-by: /usr/share/keyrings/microsoft-keyring.gpg
EOF
sudo apt update && sudo apt install -y code

# Install user softwares via Homebrew and Flatpak, too some fonts and plugins VS Code
brew bundle install

# Fisher & plugins shell
fish <<EOF
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish |
  source && fisher install jorgebucaran/fisher

fisher install jhillyerd/plugin-git
EOF

#===== Dotfiles
# Note: Using chezmoi installed via Homebrew
chezmoi init --apply https://github.com/ph-dev-br/dotfiles.git

# Appimages included in dotfiles
fp-appimages-updater update

#===== Settings
# Add user on Docker and Libvirt groups
sudo usermod -aG docker,libvirt $USER

# Services & Timers user systemd
systemctl --user enable update-packages.timer
systemctl --user enable update-core.timer

# Allow execute update-core.service without password
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/apt update, /usr/bin/apt upgrade -y" |
  sudo tee /etc/sudoers.d/update-core
sudo chmod 440 /etc/sudoers.d/update-core

# GNOME
dconf load / <dconf.ini

#===== Finishing
systemctl reboot
