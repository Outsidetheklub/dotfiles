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

## Fresh install — what to do

### 1. Install packages

```bash
sudo pacman -S stow paru yay thunar i3-wm polybar rofi rofi-calc rofi-emoji kitty fish picom \
  redshift flameshot feh polkit-gnome xorg-xrandr xorg-xinput \
  xorg-xsetroot sddm xsel ttf-meslo-nerd-font-powerlevel10k
```

```bash
git clone https://aur.archlinux.org/paru.git
```

```bash
paru -S rofi-greenclip
```

### 2. Clone + stow

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
stow */
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
