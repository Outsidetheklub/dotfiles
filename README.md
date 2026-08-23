# dotfiles

My Arch Linux configs managed with GNU Stow.

## What's inside

| Package | What it configures |
|---------|-------------------|
| `fish` | Fish shell + OpenClaw NPM path |
| `i3` | Window manager config, keybinds, startup script, mouse accel watchdog |
| `kitty` | Terminal emulator |
| `quickshell` | Bar + launcher + popups (clipboard, calc, emoji, power, wifi, bluetooth) |
| `gtk` | GTK3/GTK4 dark theme (incl. Thunar) |
| `local-bin` | Custom scripts (mouse-to-focused) |
| `picom` | Compositor (transparency, blur, shadows) |
| `redshift` | Night-time color temperature |
| `fastfetch` | System info shown on terminal open |
| `starship` | Custom prompt |
| `sddm` | SDDM config (stow with sudo to /) |
| `fontconfig` | Emoji fallback font rules (stow with sudo to /) |
| `wallpapers` | Desktop wallpaper (stow to ~) |

> Clipboard history is provided by **cliphist** (fed by `~/.config/quickshell/scripts/cliphist-watch.sh`, started from `i3/startup.sh`). The Quickshell clipboard popup reads/deletes from it.

## Fresh install — what to do

### 1. Install packages

#### Official repos

```bash
sudo pacman -S stow thunar i3-wm cliphist fastfetch kitty fish picom redshift starship flameshot feh polkit-gnome xorg-xrandr xorg-xinput xorg-xsetroot sddm qt6-virtualkeyboard noto-fonts-emoji xsel ttf-meslo-nerd eza xdotool
```

#### AUR (paru / yay)

```bash
# Install paru
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru && makepkg -si && cd ~

# AUR packages
paru -S quickshell-git ttf-meslo-nerd-font-powerlevel10k sddm-silent-theme

# Set the Silent SDDM theme to catppuccin-macchiato preset
sudo sed -i 's/^ConfigFile=.*/ConfigFile=configs\/catppuccin-macchiato.conf/' /usr/share/sddm/themes/silent/metadata.desktop
```

### 2. Clone + stow

```bash
git clone https://github.com/Outsidetheklub/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow */
sudo stow -t / sddm         # SDDM config lives in /etc
sudo stow -t / fontconfig   # Fontconfig rules (emoji fallback)
stow -t ~ wallpapers       # Wallpaper → ~/Pictures/Wallpapers/
```

### 3. Create .xprofile (fixes ghost SDDM screen)

```bash
echo '#!/bin/sh
sleep 0.5
xsetroot -solid "#1e1e2e"' > ~/.xprofile
chmod +x ~/.xprofile
```

### 4. Set keyboard layout (if not in startup)

```bash
setxkbmap se
```

### 5. Reboot

```bash
reboot
```

## Keybinds (custom)

| Key | Action |
|-----|--------|
| `$mod+space` | App launcher (Quickshell) |
| `$mod+c` | Calculator (Quickshell) |
| `$mod+v` | Clipboard history (Quickshell + cliphist) |
| `$mod+Shift+v` | Clipboard delete mode (click entries to remove) |
| `$mod+period` | Emoji picker (Quickshell) |
| `$mod+Escape` | Power menu (Quickshell) |
| `$mod+m` | Apple Music (Cider) |
| `Print` | Screenshot full (flameshot) |
| `$mod+Shift+s` | Screenshot area (flameshot) |
| `$mod+minus` | Scratchpad show |
| `$mod+Shift+minus` | Move window to scratchpad |

Everything else (display config, mouse accel fix, startup apps) is handled by `~/.config/i3/startup.sh`.
