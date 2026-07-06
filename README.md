# dotfiles

My Arch Linux configs managed with GNU Stow.

## What's inside

| Package | What it configures |
|---------|-------------------|
| `fish` | Fish shell + OpenClaw NPM path |
| `greenclip` | Clipboard history daemon + config |
| `i3` | Window manager config, keybinds, startup script, mouse accel watchdog |
| `kitty` | Terminal emulator |
| `local-bin` | Custom scripts (power menu, mouse-to-focused, clipboard rofi) |
| `picom` | Compositor (transparency, blur, shadows) |
| `polybar` | Status bar + scripts (volume, wifi, bluetooth, RAM) |
| `redshift` | Night-time color temperature |
| `rofi` | App launcher, emoji picker, calculator, clipboard history, power menu |
| `fastfetch` | System info shown on terminal open |
| `starship` | Custom prompt |
| `sddm` | SDDM config (stow with sudo to /) |
| `fontconfig` | Emoji fallback font rules (stow with sudo to /) |

## Fresh install — what to do

### 1. Install packages

#### Official repos

```bash
sudo pacman -S stow thunar i3-wm polybar rofi rofi-calc rofi-emoji fastfetch kitty fish picom redshift starship flameshot feh polkit-gnome xorg-xrandr xorg-xinput xorg-xsetroot sddm qt6-virtualkeyboard noto-fonts-emoji xsel ttf-meslo-nerd
```

#### AUR (paru / yay)

```bash
# Install paru
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si && cd ~

# Install yay
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si && cd ~

# AUR packages
paru -S rofi-greenclip ttf-meslo-nerd-font-powerlevel10k sddm-silent-theme

# Set the Silent SDDM theme to catppuccin-macchiato preset
sudo sed -i 's/^ConfigFile=.*/ConfigFile=configs\/catppuccin-macchiato.conf/' /usr/share/sddm/themes/silent/metadata.desktop
```

### 2. Clone + stow

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
stow */
sudo stow -t / sddm         # SDDM config lives in /etc
sudo stow -t / fontconfig   # Fontconfig rules (emoji fallback)
```

### 3. Copy wallpaper

```bash
mkdir -p ~/Pictures/Wallpapers
# Copy your wallpaper to ~/Pictures/Wallpapers/gregre.png
```

### 4. Create .xprofile (fixes ghost SDDM screen)

```bash
echo '#!/bin/sh
sleep 0.5
xsetroot -solid "#1e1e2e"' > ~/.xprofile
chmod +x ~/.xprofile
```

### 5. Set keyboard layout (if not in startup)

```bash
setxkbmap se
```

### 6. Reboot

```bash
reboot
```

## Keybinds (custom)

| Key | Action |
|-----|--------|
| `$mod+space` | App launcher (rofi drun) |
| `$mod+c` | Calculator (rofi calc mode) |
| `$mod+v` | Clipboard history (greenclip + rofi) |
| `$mod+Shift+v` | Delete clipboard history entry |
| `$mod+period` | Emoji picker |
| `$mod+Shift+s` | Screenshot (flameshot) |

Everything else (display config, mouse accel fix, startup apps) is handled by `~/.config/i3/startup.sh`.
