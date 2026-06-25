# dotfiles

My Arch Linux configs managed with GNU Stow.

## What's inside

| Package | What it configures |
|---------|-------------------|
| `fish` | Fish shell + OpenClaw NPM path |
| `i3` | Window manager config, keybinds, startup script |
| `kitty` | Terminal emulator |
| `local-bin` | Custom scripts (power menu, mouse-to-focused) |
| `picom` | Compositor (transparency, blur, shadows) |
| `polybar` | Status bar + scripts (volume, wifi, bluetooth, RAM) |
| `redshift` | Night-time color temperature |
| `rofi` | App launcher, emoji picker, calculator, power menu |

## Fresh install — what to do

### 1. Install packages

```bash
sudo pacman -S stow i3-wm polybar rofi rofi-calc rofi-emoji kitty fish picom \
  redshift flameshot feh polkit-gnome xorg-xrandr xorg-xinput \
  xorg-xsetroot rofi-greenclip xsel ttf-meslo-nerd-font-powerlevel10k
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

That's it. Everything else (display config, mouse accel fix, startup apps) is handled by `~/.config/i3/startup.sh`.
