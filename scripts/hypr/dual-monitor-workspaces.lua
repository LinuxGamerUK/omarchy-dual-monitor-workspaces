-- Persistent dual-monitor workspace banks (Hyprland Lua config).
-- Installed and managed by omarchy-dual-monitor-workspaces
-- (https://github.com/LinuxGamerUK/omarchy-dual-monitor-workspaces).
-- Remove with the plugin's scripts/uninstall.sh.
--
-- Monitors are ordered left-to-right (x position, then name), so no monitor
-- names are hardcoded here:
--   monitor 1 -> workspaces 1..5
--   monitor 2 -> workspaces 6..10
--   one monitor -> all 10 on that screen
--   three+ monitors -> only the first two get banks
-- Rules re-apply whenever Hyprland re-parses the config (hyprctl reload,
-- monitor hotplug re-parse, re-login). Requires Hyprland 0.55+.

local BANK_SIZE = 5
local BANK_COUNT = 2

local monitors = hl.get_monitors()

table.sort(monitors, function(a, b)
  if a.x == b.x then return a.name < b.name end
  return a.x < b.x
end)

for bank = 1, BANK_COUNT do
  local monitor = monitors[bank]
  if monitor ~= nil then
    local first = (bank - 1) * BANK_SIZE + 1
    for workspace = first, first + BANK_SIZE - 1 do
      hl.workspace_rule({
        workspace = tostring(workspace),
        monitor = monitor.name,
        persistent = true,
        default = workspace == first,
      })
    end
  end
end

-- Single monitor: stack the second bank on the same output so moving to
-- workspaces 6..10 still lands on the only screen instead of floating.
if #monitors == 1 then
  for workspace = BANK_SIZE + 1, BANK_SIZE * BANK_COUNT do
    hl.workspace_rule({
      workspace = tostring(workspace),
      monitor = monitors[1].name,
      persistent = true,
    })
  end
end