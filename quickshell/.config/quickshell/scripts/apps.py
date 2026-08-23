#!/usr/bin/env python3
"""List installed GUI apps as TSV: name<TAB>exec<TAB>icon-path

Parses .desktop files like rofi's drun mode. Strips field codes from Exec.
Icon resolution: name -> Adwaita/hicolor theme paths -> full path -> "" (fallback).
"""
import configparser
import glob
import os
import sys

APP_DIRS = [
    "/usr/share/applications",
    "/usr/local/share/applications",
    os.path.expanduser("~/.local/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
]

ICON_ROOTS = [
    "/usr/share/icons/Adwaita",
    "/usr/share/icons/hicolor",
    os.path.expanduser("~/.local/share/icons/hicolor"),
]

ICON_SIZES = ["scalable", "256x256", "128x128", "64x64", "48x48", "32x32", "24x24", "16x16"]
ICON_EXTS = [".svg", ".svgz", ".png"]

FIELD_CODES = ["%f", "%F", "%u", "%U", "%d", "%D", "%n", "%N", "%i", "%c", "%k", "%v", "%m"]


def find_icon(icon: str) -> str:
    """Resolve an icon name or path to an existing file."""
    if not icon:
        return ""
    if icon.startswith("/") and os.path.exists(icon):
        return icon
    # bare name: look in theme dirs
    for root in ICON_ROOTS:
        for size in ICON_SIZES:
            for ext in ICON_EXTS:
                p = os.path.join(root, size, "apps", icon + ext)
                if os.path.exists(p):
                    return p
    return ""


def clean_exec(exec_line: str) -> str:
    """Strip desktop-entry field codes and trailing args we don't need."""
    for code in FIELD_CODES:
        exec_line = exec_line.replace(code, "")
    # drop everything after the first field-code-ish remainder
    exec_line = exec_line.strip()
    # remove common wrappers
    exec_line = exec_line.replace("env ", "", 1)
    return exec_line


def main() -> None:
    seen = set()
    apps = []
    for d in APP_DIRS:
        if not os.path.isdir(d):
            continue
        for f in sorted(glob.glob(os.path.join(d, "*.desktop"))):
            try:
                cp = configparser.ConfigParser(interpolation=None)
                cp.read(f)
                if not cp.has_section("Desktop Entry"):
                    continue
                e = cp["Desktop Entry"]
                if e.get("Type", "") != "Application":
                    continue
                if e.getboolean("NoDisplay", False) or e.getboolean("Hidden", False):
                    continue
                name = e.get("Name", "").strip()
                ex = e.get("Exec", "").strip()
                if not name or not ex:
                    continue
                # skip flatpak run wrappers that are just launchers? keep them, they work.
                icon = find_icon(e.get("Icon", "").strip())
                ex = clean_exec(ex)
                key = (name.lower(), ex)
                if key in seen:
                    continue
                seen.add(key)
                apps.append((name, ex, icon))
            except Exception:
                continue

    apps.sort(key=lambda a: a[0].lower())
    out = sys.stdout
    for name, ex, icon in apps:
        out.write(f"{name}\t{ex}\t{icon}\n")


if __name__ == "__main__":
    main()
