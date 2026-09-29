#!/usr/bin/env bash
# Install persistent dual-monitor workspace banks for Omarchy / Hyprland.
#
# What it does (all user-scoped, no sudo):
#   1. Copies dual-monitor-workspaces.lua into ~/.config/hypr/
#   2. Appends a marked require() block to ~/.config/hypr/hyprland.lua
#      (idempotent; a timestamped backup is made before editing)
#   3. Reloads Hyprland and reports the resulting persistent banks
#
# Usage:  scripts/install.sh
# Remove: scripts/uninstall.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_SRC="$SCRIPT_DIR/hypr/dual-monitor-workspaces.lua"
HYPR_DIR="$HOME/.config/hypr"
RULES_DST="$HYPR_DIR/dual-monitor-workspaces.lua"
HYPR_CONF="$HYPR_DIR/hyprland.lua"
BLOCK_OPEN="-- >>> dual-monitor-workspaces (omarchy plugin, do not edit by hand)"
BLOCK_CLOSE="-- <<< dual-monitor-workspaces"
REQUIRE_LINE='require("hypr.dual-monitor-workspaces")'

fail() { echo "error: $*" >&2; exit 1; }

command -v hyprctl >/dev/null 2>&1 || fail "hyprctl not found - run this inside an Omarchy/Hyprland session"
[ -f "$RULES_SRC" ] || fail "rules template missing: $RULES_SRC"
[ -d "$HYPR_DIR" ] || fail "$HYPR_DIR not found - is this an Omarchy/Hyprland machine?"
[ -f "$HYPR_CONF" ] || fail "$HYPR_CONF not found - cannot wire up the rules"

# 1. Rules file (overwrites quietly for re-installs/upgrades).
install -m 0644 "$RULES_SRC" "$RULES_DST"
echo "installed: $RULES_DST"

# 2. Require block in hyprland.lua (idempotent, with backup).
if grep -qF -- "$BLOCK_OPEN" "$HYPR_CONF"; then
  echo "present:   $REQUIRE_LINE (already wired in hyprland.lua)"
else
  BACKUP="$HYPR_CONF.bak.dual-monitor-workspaces.$(date +%Y%m%d-%H%M%S)"
  cp -p "$HYPR_CONF" "$BACKUP"
  echo "backup:    $BACKUP"
  {
    echo ""
    echo "$BLOCK_OPEN"
    echo "$REQUIRE_LINE"
    echo "$BLOCK_CLOSE"
  } >> "$HYPR_CONF"
  echo "wired:     $REQUIRE_LINE appended to hyprland.lua"
fi

# 3. Reload and verify.
hyprctl reload >/dev/null 2>&1 || true
sleep 1

ERRORS="$(hyprctl configerrors 2>/dev/null || true)"
if [ -n "$(printf '%s' "$ERRORS" | tr -d '[:space:]')" ]; then
  echo "warning: Hyprland reports config errors:" >&2
  printf '%s\n' "$ERRORS" >&2
  exit 1
fi

echo
echo "persistent workspace banks now active:"
hyprctl -j workspaces 2>/dev/null | python3 -c '
import json, sys
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit(0)
banks = {}
for ws in rows:
    if not ws.get("ispersistent") and not ws.get("persistent"):
        continue
    mon = (ws.get("monitor") or "?")
    banks.setdefault(mon, []).append(ws.get("id"))
for mon in sorted(banks):
    print("  " + mon + ": workspaces " + ", ".join(map(str, sorted(banks[mon]))))
if not banks:
    print("  (none found - did Hyprland finish reloading?)")
'

echo
echo "done. SUPER+1..5 focus/move on bank 1, SUPER+6..0 on bank 2 (Omarchy default binds)."
echo "note: 'omarchy refresh hyprland' rewrites hyprland.lua - re-run this script afterwards."