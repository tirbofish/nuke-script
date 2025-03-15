#!/bin/bash

# Error handling
set -e  # Exit on error
trap 'echo "Error occurred at line $LINENO. Command: $BASH_COMMAND"' ERR

echo "
===================================================================
                        INSTALL SCRIPT
        For Arch Linux and customised for Surface Pro
- for 4tkbytes (me)                                    v1 | 15/3/25

===================================================================

"

# Check if script is run as root (which is not recommended)
if [ "$(id -u)" = 0 ]; then
    echo "This script should not be run as root!" >&2
    exit 1
fi

echo "----- This script assumes you have admin privileges -----"

# Setup passwordless sudo
echo "Setting up passwordless sudo for current user"
echo "$(whoami) ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$(whoami)
sudo chmod 440 /etc/sudoers.d/$(whoami)
echo "Passwordless sudo configured for $(whoami)"

# Create backup directory
BACKUP_DIR="$HOME/script_backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "----- Creating backups of configuration files -----"
[ -f ~/.bashrc ] && cp ~/.bashrc "$BACKUP_DIR/bashrc.bak"
[ -f ~/.bash_profile ] && cp ~/.bash_profile "$BACKUP_DIR/bash_profile.bak"
echo "Backups saved to $BACKUP_DIR"

echo "----- Pacman update -----"
sudo pacman -Syu --noconfirm

echo "----- Installing AUR installer (yay) -----"
sudo pacman -S --needed git base-devel --noconfirm
cd /tmp
if [ -d yay ]; then
    # Remove the directory with sudo to avoid permission errors
    sudo rm -rf yay
fi
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm

echo "alias pacitup='sudo pacman --noconfirm --needed'" >> ~/.bashrc

echo "----- Installing apps of choice -----"
yay -S gnome gnome-extras firefox ani-cli flatpak openvpn-update-systemd-resolved \
    arch-update bottles cpupower-gui surface-control \
    extension-manager filen-desktop-bin google-chrome auto-cpufreq \
    heroic-games-launcher-bin jetbrains-toolbox libwacom-surface \
    millenium minecraft-launcher openvpn-update-systemd-resolved \
    pipes.sh spofity spicetify-cli timeshift-autosnap ttf-ms-fonts \
    ttf-ms-win11-auto-japanese ttf-ms-win11-auto-other vesktop-bin thermald \
    visual-studio-code-bin webapp-manager yt-dlp zen-browser-bin systemd-resolvconf \
    ghostty rclone meson minecraft-launcher ghostty-shell-integration \
    ghostty-terminfo unzip tar zip thefuck extension-manager proton-vpn-gtk-app \
    arch-update github-cli libreoffice-fresh gimp brave-bin pipx wireguard-tools \
    --sudoloop --answerdiff=None --answeredit=None --answerclean=None --answerupgrade=None --needed \
    --noconfirm

echo " ----- Adding Surface-Linux Key ----- "
curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | sudo pacman-key --add -

sudo pacman-key --finger 56C464BAAC421453
sudo pacman-key --lsign-key 56C464BAAC421453

# Check if the repository is already in pacman.conf
if ! grep -q "\[linux-surface\]" /etc/pacman.conf; then
    sudo bash -c 'echo "[linux-surface]" >> /etc/pacman.conf'
    sudo bash -c 'echo "Server = https://pkg.surfacelinux.com/arch/" >> /etc/pacman.conf'
fi

echo " ----- Installing linux-surface kernel ----- "
sudo pacman -Syu --noconfirm
sudo pacman -S linux-surface linux-surface-headers iptsd linux-surface-secureboot-mok --noconfirm --needed

echo " ----- Adding config to grub ----- "
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo " ----- Installing SDKMan (for jvm languages) ----- "
curl -s "https://get.sdkman.io" | bash

# Only add to bashrc if not already there
if ! grep -q "SDKMAN_DIR" ~/.bashrc; then
    echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> ~/.bashrc
    echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> ~/.bashrc
fi

source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk version
sdk install java
sdk install kotlin
sdk install gradle
sdk install maven

echo " ----- Installing Rustlang and Cargo with complete profile ----- "
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile complete
. "$HOME/.cargo/env"

echo " ----- Installing homebrew ----- "
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Only add to bashrc if not already there
if ! grep -q "brew shellenv" ~/.bashrc; then
    echo >> ~/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

sudo pacman -S base-devel --noconfirm --needed
echo " ----- Testing Linuxbrew by installing gcc ----- "
brew install gcc

# Only add to bashrc if not already there
if ! grep -q "thefuck --alias" ~/.bashrc; then
    echo " ----- Adding thefuck to bashrc ----- "
    echo 'eval "$(thefuck --alias)"' >> ~/.bashrc
fi

echo " ----- Setting surface profile to balanced ----- "
sudo surface profile set balanced

# Create cpupower_gui directory if it doesn't exist
mkdir -p ~/.config/cpupower_gui

# Create the CPU power profile for balanced22
cat << 'EOF' > ~/.config/cpupower_gui/cpg-balanced22.profile
# name: balanced22

# CPU	Min	Max	Governor	Online
0	400	2200	performance	True
1	400	2200	performance	True
2	400	2200	performance	True
3	400	2200	performance	True
4	400	2200	performance	True
5	400	2200	performance	True
6	400	2200	performance	True
7	400	2200	performance	True
EOF

echo " ----- Custom CPU profile 'balanced22' created ----- "

echo " ----- Installing libinput fix ----- "
sudo touch /etc/libinput.conf
sudo bash -c "echo 'scroll-factor-y=0.5' >> /etc/libinput.conf"
sudo bash -c "echo 'scroll-factor-x=0.75' >> /etc/libinput.conf"
echo "Created config file @ /etc/libinput.conf"

cd ~
[ -d libinput-config ] && rm -rf libinput-config
git clone https://gitlab.com/warningnonpotablewater/libinput-config
cd libinput-config
meson build
cd build
ninja
sudo ninja install
cd ~

echo " ----- Installing wine and steam ----- "
sudo pacman -S wine steam --noconfirm --needed

echo " ----- Installing Roblox (sober) -----"
flatpak install https://sober.vinegarhq.org/sober.flatpakref -y

# Download wallpaper and set it
WALLPAPER_DIR="$HOME/Pictures/"
mkdir -p "$WALLPAPER_DIR"
WALLPAPER_PATH="$WALLPAPER_DIR/downloaded_wallpaper.png"
PFP="$WALLPAPER_DIR/downloaded_profile.jpg"

echo "----- Downloading wallpaper... -----"
curl -s "https://images5.alphacoders.com/135/thumb-1920-1353199.png" -o "$WALLPAPER_PATH"

if [ -f "$WALLPAPER_PATH" ]; then
    echo "----- Setting wallpaper... -----"
    gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_PATH"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_PATH"
    echo "----- Wallpaper set successfully! -----"
else
    echo "----- Failed to download wallpaper -----"
fi

if command -v ghostty &>/dev/null; then
    echo "----- Ghostty is installed. Removing gnome-terminal and gnome-console... -----"
    sudo pacman -R gnome-terminal gnome-console --noconfirm
else
    echo "----- Ghostty not found. Installing ghostty -----"
    sudo pacman -S ghostty --noconfirm
fi

curl -s "https://i.pinimg.com/564x/2e/ee/b4/2eeeb449f0a17733112cf65d69a1a2d5.jpg" -o "$PFP"

pipx install gnome-extensions-cli --system-site-packages

echo "----- Adding in gnome QOL extensions -----"
gext install appindicatorsupport@rgcjonas.gmail.com
gext install blur-my-shell@aunext
gext install dash-to-dock@micxgx.gmail.com
gext install fullscreen-to-empty-workspace2@corgijan.dev
gext install lockscreen-extension@pratap.fastmail.fm
gext install open-desktop-location@laura.media

echo "----- Installing snapd -----"
cd ~
[ -d snapd ] && rm -rf snapd
git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si --noconfirm

echo "----- evil hello world mwehaha -----"
sudo systemctl enable --now snapd.socket
sudo systemctl enable --now snapd.apparmor.service
sudo ln -sf /var/lib/snapd/snap /snap
snap install hello-world

cd ~

# Only add to bashrc if not already there
if ! grep -q "alias yep=" ~/.bashrc; then
    echo "alias yep='yay --sudoloop --answerdiff=None --answeredit=None'" >> ~/.bashrc
fi

# Only add to bashrc if not already there
if ! grep -q "fastfetch" ~/.bashrc; then
    echo 'fastfetch' >> ~/.bashrc
fi

source ~/.bashrc
yay -Syu --sudoloop --answerdiff=None --answeredit=None --answerclean=None --answerupgrade=None --noconfirm

mkdir -p ~/filen.io

# Remove passwordless sudo at the end
sudo rm /etc/sudoers.d/$(whoami)
echo "----- Removed passwordless sudo configuration -----"

echo "

  _________________________       ___________________________
-/                         \-----/                           \-
SETUP HAS FINISHED... Have fun with your new system 4tkbytes!

===================================================================
Before doing anything, make sure to reboot your system to save all the changes. 

TODO for you: 
    - Change your profile picture to the silly teto @ $PFP
    - Check if there were any errors on the customisation script
    - Login to all your services on your browser of choice
    - Sync with Filen.io
    - Install JetBrains Apps
    - Install Davinci Resolve
    - Add your GitHub SSH and GPG Key
    - Download VPN config files from ProtonVPN

===================================================================
                        ENJOY!!! :3
"