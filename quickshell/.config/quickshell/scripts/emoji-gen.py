#!/usr/bin/env python3
"""Convert emoji-test.txt into a TSV for the Quickshell emoji picker.

Output lines: <emoji>\t<name>
Only fully-qualified + minimally-qualified entries (the ones that render as color emoji).
"""
import os
import sys

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "emoji-test.txt")


def main() -> None:
    out = []
    with open(SRC, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            # format: CODEPOINTS ; status # EMOJI E.VERSION name
            if ";" not in line:
                continue
            left, _, right = line.partition(";")
            status = right.split("#", 1)[0].strip()
            if status not in ("fully-qualified", "minimally-qualified"):
                continue
            comment = right.split("#", 1)[1].strip() if "#" in right else ""
            # strip the emoji itself + the version token
            parts = comment.split(" ", 2)
            name = parts[2] if len(parts) > 2 else (parts[1] if len(parts) > 1 else comment)
            codepoints = [int(cp, 16) for cp in left.strip().split()]
            emoji = "".join(chr(cp) for cp in codepoints)
            out.append(f"{emoji}\t{name}")

    for line in out:
        print(line)


if __name__ == "__main__":
    main()
