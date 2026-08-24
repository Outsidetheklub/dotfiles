#!/usr/bin/env python3
"""Print the name of the focused window from `i3-msg -t get_tree` JSON.

Replaces the jq one-liner so the bar doesn't depend on jq being installed.
"""
import json
import sys


def find_focused(node):
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        if child.get("focused") and child.get("window") and child.get("name"):
            print(child["name"])
            return True
        if find_focused(child):
            return True
    return False


find_focused(json.load(sys.stdin))
