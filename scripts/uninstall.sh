#!/usr/bin/env bash
# Remove the persistent dual-monitor workspace banks installed by install.sh.
# The bar widget itself is removed with:
#   omarchy plugin remove io.github.linuxgameruk.dual-monitor-workspaces
set -euo pipefail

HYPR_DIR="$HOME/.config/hypr"
RULES_DST="$HYPR_DIR/dual-monitor-workspaces.lua"
HYPR_CONF="$HYPR_DIR/hyprland.lua"
BLOCK_OPEN="-- >>> dual-monitor-workspaces (omarchy plugin, do not edit by hand)"
BLOCK_CLOSE="-- <<< dual-monitor-workspaces"

command -v hyprctl >/dev/null 2>&1 || { echo "error: hyprctl not found" >&2; exit 1; }

if [ -f "$HYPR_CONF" ] && grep -qF -- "$BLOCK_OPEN" "$HYPR_CONF"; then
  BACKUP="$HYPR_CONF.bak.dual-monitor-workspaces.remove.$(date +%Y%m%d-%H%M%S)"
  cp -p "$HYPR_CONF" "$BACKUP"
  echo "backup: $BACKUP"
  TMP="$(mktemp)"
  awk -v block_open="$BLOCK_OPEN" -v block_close="$BLOCK_CLOSE" '
    $0 == block_open { skip = 1; next }
    $0 == block_close { skip = 0; next }
    skip == 0 { print }
  ' "$HYPR_CONF" > "$TMP"
  mv "$TMP" "$HYPR_CONF"
  echo "removed: require block from hyprland.lua (and surrounding blank lines trimmed next edit)"
else
  echo "present: no wiring block found in hyprland.lua (nothing to do)"
fi

if [ -f "$RULES_DST" ]; then
  rm -f "$RULES_DST"
  echo "removed: $RULES_DST"
fi

hyprctl reload >/dev/null 2>&1 || true
sleep 1
echo
echo "workspaces still persistent:"
hyprctl -j workspaces 2>/dev/null | python3 -c '
import json, sys
try:
    rows = json.load(sys.stdin)
except Exception:
    sys.exit(0)
found = sum(1 for ws in rows if ws.get("persistent"))
print("  " + str(found))
'
echo "done. numbered workspaces behave like Omarchy defaults again (SUPER+5 vs SUPER+6 are no longer monitor-bound)."